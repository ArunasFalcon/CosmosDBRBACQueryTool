function Get-CosmosAuthHeaders{
    param(
        [string]$PartitionKey
    )

    $authscope = "https://cosmos.azure.com"
    $token = (Get-AzAccessToken -ResourceUrl $authscope).Token
    $authplain = [System.Web.HttpUtility]::UrlEncodeUnicode("type=aad&ver=1.0&sig=$token")
    $headers = @{
        "Authorization" = $authplain
        "x-ms-version" = "2018-12-31"
        "Content-Type" = "application/query+json"
        "Accept" = "application/json"
        "x-ms-date" = (Get-Date -Format r).ToString()
        "x-ms-documentdb-isquery" = "True"
        "x-ms-documentdb-query-enablecrosspartition" = "True"
    }
    if ($PartitionKey)
    {
        $headers.Add("x-ms-documentdb-partitionkey","[`"$PartitionKey`"]")
    }
    return $headers
}

function Get-CosmosQueryResults{
    param(
        [string]$CosmosDBAccount,
        [string]$DBName,
        [string]$ContainerName,
        [string]$Query
    )

    $CosmosAccountEndpoint = "https://${CosmosDBAccount}.documents.azure.com"
    $uri = "${CosmosAccountEndpoint}/dbs/$DBName/colls/$ContainerName/docs"
    $headers = Get-CosmosAuthHeaders
    $queryObj = @{
        "query" = $Query
        "parameters" = @()
    }
    $body = $queryObj | ConvertTo-Json
    $result = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
    return $result
}

function Invoke-CosmosStoredProcedure{
    param(
        [string]$CosmosDBAccount,
        [string]$DBName,
        [string]$ContainerName,
        [string]$StoredProcedureId,
        [string]$PartitionKey,
        [array]$StoredProcedureParameters
    )

    $CosmosAccountEndpoint = "https://${CosmosDBAccount}.documents.azure.com"
    $uri = "${CosmosAccountEndpoint}/dbs/$DBName/colls/$ContainerName/sprocs/$StoredProcedureId"
    $headers = Get-CosmosAuthHeaders -PartitionKey $PartitionKey
    if ($null -eq $StoredProcedureParameters)
    {
        $body = ''
    }
    else
    {
        $body = ConvertTo-Json -InputObject $StoredProcedureParameters
    }
    $result = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
    return $result
}

Export-ModuleMember -Function Get-CosmosQueryResults
Export-ModuleMember -Function Invoke-CosmosStoredProcedure
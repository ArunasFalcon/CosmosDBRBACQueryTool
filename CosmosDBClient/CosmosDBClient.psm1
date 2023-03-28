function Get-CosmosAuthHeaders{
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

Export-ModuleMember -Function Get-CosmosQueryResults

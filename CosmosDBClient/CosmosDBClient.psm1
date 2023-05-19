function Get-CosmosAuthHeaders{
    param(
        [string]$PartitionKey,
        [string]$ContinuationToken = "",
        [switch]$Replace
    )

    $authscope = "https://cosmos.azure.com"
    $token = (Get-AzAccessToken -ResourceUrl $authscope).Token
    $authplain = [System.Web.HttpUtility]::UrlEncodeUnicode("type=aad&ver=1.0&sig=$token")
    $headers = @{
        "Authorization" = $authplain
        "x-ms-version" = "2018-12-31"
        "Accept" = "application/json"
        "x-ms-date" = (Get-Date -Format r).ToString()
        "x-ms-documentdb-query-enablecrosspartition" = "True"
        "x-ms-continuation" = $ContinuationToken
    }
    if ($PartitionKey)
    {
        $headers.Add("x-ms-documentdb-partitionkey","[`"$PartitionKey`"]")
    }
    if ($Replace)
    {
        $headers.Add("Content-Type", "application/json_patch+json")
    }
    else
    {
        $headers.Add("Content-Type", "application/query+json")
        $headers.Add("x-ms-documentdb-isquery", "True")
    }
    return $headers
}

function Set-CosmosDocument{
    param(
        [string]$CosmosDBAccount,
        [string]$DBName,
        [string]$ContainerName,
        [string]$PartitionKey,
        [string]$DocumentId,
        [object]$Content
    )

    $CosmosAccountEndpoint = "https://${CosmosDBAccount}.documents.azure.com"
    $uri = "${CosmosAccountEndpoint}/dbs/$DBName/colls/$ContainerName/docs/$DocumentId"
    $body = $Content | ConvertTo-Json -Depth 100
    $headers = Get-CosmosAuthHeaders -PartitionKey $PartitionKey -Replace
    $result = Invoke-RestMethod -Method Put -Headers $headers -Uri $uri -Body $body
    return $result
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
    $queryObj = @{
        "query" = $Query
        "parameters" = @()
    }
    $body = $queryObj | ConvertTo-Json
    $continuationToken = ""
    $first = $true
    $resultCollector = [System.Collections.Generic.List[object]]::new()
    $totalRUs = 0

    do {
        $headers = Get-CosmosAuthHeaders -ContinuationToken $continuationToken
        $result = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -Body $body -SkipHttpErrorCheck
        if ($result.StatusCode -eq 429){
            Write-Host "Request throttled, waiting for retry"
            Start-Sleep -Seconds 5.0
        }
        elseif ($result.StatusCode -gt 300){
            throw "Status code ${result.StatusCode}"
        }
        else{
            $first = $false
            $docs = $result.Content | ConvertFrom-Json
            $resultCollector.AddRange($docs.Documents)
            $continuationToken = $result.Headers['x-ms-continuation']
            $requestRUs = [double]::Parse($result.Headers['x-ms-request-charge'])
            Write-Host "This request charge: $requestRUs"
            $totalRUs = $totalRUs + $requestRUs
        }
    } while ($continuationToken -or $first)

    Write-Host "Total RU charge: $totalRUs"

    return $resultCollector
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
Export-ModuleMember -Function Set-CosmosDocument

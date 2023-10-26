function Send-CluedInIngestionData {
    <#
        .SYNOPSIS
        GraphQL Query: Sends JSON data to a specified ingestion endpoint guid

        .DESCRIPTION
        GraphQL Query: Sends JSON data to a specified ingestion endpoint guid

        .PARAMETER Json
        This is raw JSON content in string format. Can be single or multiline

        .PARAMETER IngestionEndpoint
        This is the endpoint guid that data will be sent to

        .EXAMPLE
        PS> $json = Get-Content -Path /path/to/data/60-Persons.json -raw
        PS> Send-CluedInIngestionData -Json $Json -IngestionEndpoint ae145ff5-450b-46b2-8d02-7662dee2beb3
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Json,
        [Parameter(Mandatory)][guid]$IngestionEndpoint
    )

    if (!(Test-Json -Json $Json)) {
        Write-Error "Issue with submitted Json, please check content"
        return
    }

    $Uri = '{0}/upload/api/endpoint/{1}' -f ${env:CLUEDIN_ENDPOINT}, $IngestionEndpoint
    return Invoke-CluedInWebRequest -Uri $Uri -Method 'POST' -Body $Json
}
function Invoke-CluedInGraphQL {
    <#
        .SYNOPSIS
        Wrapper for Invoke-CluedInWebRequest to the graphql endpoint

        .DESCRIPTION
        Wrapper for Invoke-CluedInWebRequest to the graphql endpoint.

        Allows functions to easily be created without much thought into how to reach the endpoint. 
        All GraphQL sub-functions should go through this function.

        .PARAMETER Query
        single string input that's sent to the next function. It should be in JSON format and matches what you'd send to GraphQL.

        .EXAMPLE
        PS> Invoke-CluedInGraphQL -Query '{"query":"query getConfigurationSettings() {}"}'
        
        This will send the GraphQL query to the GraphQL endpoint
    #>

    [CmdletBinding()]
    param(
        [hashtable]$Query
    )

    $endpoint = ${env:CLUEDIN_ENDPOINT} + "/graphql"
    Write-Debug "endpoint: $endpoint"

    [string]$body = $Query | ConvertTo-Json -Compress -Depth 20

    $response = Invoke-CluedInWebRequest -Uri $endpoint -Body $body -Method 'POST'
    Write-Debug "status: $response"

    return $response
}
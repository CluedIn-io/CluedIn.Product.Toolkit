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

    if ($Query['variables']['pageNumber']) {
        Write-Verbose "Pagination required as variable 'pageNumber' was detected"

        $exclusionList = @( 'id', '__typename' )
        $propertyA = $response.data.psobject.Properties.name
        $propertyB = $response.data.$propertyA.psobject.Properties.name | Where-Object { $_ -notin $exclusionList }
        $total = $response.data.$propertyA.$propertyB.total

        if ($total -gt $query['variables']['itemsPerPage']) {
            while ($true) {
                Write-Verbose "Paginating: Page '$($query['variables']['pageNumber'])'"

                $query['variables']['pageNumber']++
                [string]$body = $Query | ConvertTo-Json -Compress -Depth 20
                $nextPage = Invoke-CluedInWebRequest -Uri $endpoint -Body $body -Method 'POST'
                $response.data.$propertyA.$propertyB.data += $nextPage.data.$propertyA.$propertyB.data
                if ($response.data.$propertyA.$propertyB.data.count -ge $total) { break }
            }
        }
    }
    Write-Debug "status: $response"

    return $response
}
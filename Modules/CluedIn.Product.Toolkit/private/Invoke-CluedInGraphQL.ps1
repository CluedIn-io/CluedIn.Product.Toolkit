function Invoke-CluedInGraphQL {
    <#
        .SYNOPSIS
        Wrapper for Invoke-CluedInWebRequest to the GraphQL endpoint

        .DESCRIPTION
        Wrapper for Invoke-CluedInWebRequest to the GraphQL endpoint.

        Allows functions to easily be created without much thought into how to reach the endpoint.
        All GraphQL sub-functions should go through this function.
        Will automatically paginate when the variable pageNumber or page exists

        .PARAMETER Query
        A hashtable input that's sent to Invoke-CluedInWebRequest.
        This is part of most public functions.

        .EXAMPLE
        PS> Invoke-CluedInGraphQL -Query $Hashtable

        This will send the GraphQL query and variables to the GraphQL endpoint
    #>

    [CmdletBinding()]
    param(
        [hashtable]$Query
    )

    $endpoint = ${env:CLUEDIN_ENDPOINT} + "/graphql"
    Write-Debug "endpoint: $endpoint"

    [string]$body = $Query | ConvertTo-Json -Compress -Depth 20

    $response = Invoke-CluedInWebRequest -Uri $endpoint -Body $body -Method 'POST'

    if (HasPagination($Query)) {
        $pageSize = GetPageSize($Query)
        $exclusionList = @( 'id', '__typename' )
        $propertyA = $response.data.psobject.Properties.name
        $propertyB = $response.data.$propertyA.psobject.Properties.name | Where-Object { $_ -notin $exclusionList }
        $total = $response.data.$propertyA.$propertyB.total

        if ($total -gt $pageSize) {
            while ($true) {
                IncreasePageCount($Query)

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

function HasPagination([hashtable]$Query){
    return $Query['variables'].ContainsKey('pageNumber') -or $Query['variables'].ContainsKey('page')
}

function IncreasePageCount([hashtable]$Query){
    if ($Query['variables'].ContainsKey('pageNumber')) {
        $query['variables']['pageNumber']++
    }elseif ($Query['variables'].ContainsKey('page')){
        $query['variables']['page']++
    }
}

function GetPageSize([hashtable]$Query){
    if ($Query['variables'].ContainsKey('itemsPerPage')) {
        return $query['variables']['itemsPerPage']
    }elseif ($Query['variables'].ContainsKey('pageSize')){
        return $query['variables']['pageSize']
    }else{
        return 20
    }
}
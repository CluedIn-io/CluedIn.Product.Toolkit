function Get-CluedInStreams {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about streams

        .DESCRIPTION
        GraphQL Query: Returns information about streams

        .PARAMETER Search
        Narrows search results. By default will return everything

        .EXAMPLE
        PS> Get-CluedInStreams
    #>

    [CmdletBinding()]
    param(
        [string]$Search = ""
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getStreams'

    $query = @{
        variables = @{
            sortBy = $null
            sortDirection = $null
            itemsPerPage = 20
            pageNumber = 1
            isActive = $null
            searchName = $null
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
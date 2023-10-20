function Get-CluedInRules {
    [CmdletBinding()]
    param(
        [guid]$Id
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

    $result = Invoke-CluedInGraphQL -Query $query

    return $result
}
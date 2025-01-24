function Get-CluedInDeduplicationProjects {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all deduplication projects

        .DESCRIPTION
        GraphQL Query: Returns all deduplication projects

        .EXAMPLE
        PS> Get-CluedInDeduplicationProjects

        This will return back all Deduplication Projects
    #>

    [CmdletBinding()]
    param(
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getDeduplicationProjects'

    $query = @{
        variables = @{
            page = 1
            itemsPerPage = 20
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
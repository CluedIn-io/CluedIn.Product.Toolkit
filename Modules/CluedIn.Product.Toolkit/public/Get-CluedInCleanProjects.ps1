function Get-CluedInCleanProjects {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all clean projects

        .DESCRIPTION
        GraphQL Query: Returns all clean projects

        .EXAMPLE
        PS> Get-CluedInCleanProjects

        This will return back all Clean Projects
    #>

    [CmdletBinding()]
    param(
        [string]$Search = ""
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'allCleanProjects'

    $query = @{
        variables = @{
            page = 1
            pageSize = 20
            searchName = $Search
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
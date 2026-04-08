function Get-CluedInManualDataEntryProjects {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about manual data entry projects

        .DESCRIPTION
        GraphQL Query: Returns information about manual data entry projects

        .EXAMPLE
        PS> Get-CluedInManualDataEntryProjects
    #>

    [CmdletBinding()]
    param(
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getManualDataEntryProjects'

    $query = @{
        variables = @{
            pageSize = 20
            pageNumber = 0
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Get-CluedInExportTargets {
    <#
        .SYNOPSIS
        GraphQL Query: Gets all Export Targets (Connectors)

        .DESCRIPTION
        GraphQL Query: Gets all Export Targets (Connectors)

        .PARAMETER Search
        Allows you to filter results rather than returning everything

        .EXAMPLE
        PS> Get-CluedInExportTargets

        If no -Search is specified, it will return everything

        .EXAMPLE
        PS> Get-CluedInExportTargets -Search "SampleStream"
    #>

    [CmdletBinding()]
    param(
        [string]$Search = ''
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAllConnectors'

    $query = @{
        variables = @{
            searchName = $Search
            itemsPerPage = 10
            pageNo = 1
            sortBy = $null
            sortDirection = $null
            status = 'All'
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
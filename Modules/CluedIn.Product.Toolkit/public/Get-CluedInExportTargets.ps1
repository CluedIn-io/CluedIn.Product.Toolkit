function Get-CluedInConnectors {
    <#
        .SYNOPSIS
        GraphQL Query: Gets all connectors (Export Targets)

        .DESCRIPTION
        GraphQL Query: Gets all connectors (Export Targets)

        .PARAMETER Search
        Allows you to filter results rather than returning everything

        .EXAMPLE
        PS> Get-CluedInConnectors

        If no -Search is specified, it will return everything

        .EXAMPLE
        PS> Get-CluedInConnectors -Search "SampleStream"
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
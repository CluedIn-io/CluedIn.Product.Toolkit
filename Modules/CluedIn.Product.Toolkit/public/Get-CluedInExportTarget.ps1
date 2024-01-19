function Get-CluedInExportTarget {
    <#
        .SYNOPSIS
        GraphQL Query: Gets configuration of an Export Target (Connector)

        .DESCRIPTION
        GraphQL Query: Gets configuration of an Export Target (Connector)

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
        [Parameter(Mandatory)][guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'connectorConfigurationById'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Get-CluedInInstalledExportTargets {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all available Export Targets (Connectors)

        .DESCRIPTION
        GraphQL Query: Returns all available Export Targets (Connectors)

        .EXAMPLE
        PS> Get-CluedInInstalledExportTargets
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getInstalledConnectors'

    $query = @{
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function New-CluedInExportTarget {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new Export Target (Connector)

        .DESCRIPTION
        GraphQL Query: Creates a new Export Target (Connector)

        .PARAMETER Search
        Allows you to filter results rather than returning everything

        .EXAMPLE
        PS> New-CluedInExportTarget -ConnectorId '87e51d3c-a0fa-4c7e-aa62-68d2ec1c3f35' -AuthInfo $AuthInfo

        If no -Search is specified, it will return everything
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$ConnectorId,
        [PSCustomObject]$Configuration
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createConnection'

    $query = @{
        variables = @{
            connectorId = $ConnectorId
            authInfo = $Configuration
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
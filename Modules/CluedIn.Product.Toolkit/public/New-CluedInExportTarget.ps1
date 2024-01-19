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
        [PSCustomObject]$AuthInfo
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createConnection'

    $query = @{
        variables = @{
            connectorId = $ConnectorId # This is ID of connector. Not sure if different each env
            authInfo = $AuthInfo # This changes each kind of connector, but variables are same
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
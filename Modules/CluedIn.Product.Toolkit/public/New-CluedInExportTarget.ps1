function New-CluedInExportTarget {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new Export Target (Connector)

        .DESCRIPTION
        GraphQL Query: Creates a new Export Target (Connector)

        .PARAMETER ConnectorId
        The unique identifier for the connector.

        .PARAMETER Configuration
        Configuration object containing authentication and other settings.

        .PARAMETER AccountDisplay
        (Optional) Display name for the account. Maintained for backward compatibility.

        .EXAMPLE
        PS> New-CluedInExportTarget -ConnectorId '87e51d3c-a0fa-4c7e-aa62-68d2ec1c3f35' -Configuration $Config

        If no -AccountDisplay is specified, it will default to a predefined value or omit it.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$ConnectorId,
        [PSCustomObject]$Configuration,
        [Parameter(Mandatory = $false)][string]$AccountDisplay
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createConnection'

    $variables = @{
        connectorId = $ConnectorId
        authInfo    = $Configuration
    }

    if ($PSBoundParameters.ContainsKey('AccountDisplay') -and $AccountDisplay) {
        $variables.accountDisplay = $AccountDisplay
    }

    $query = @{
        variables = $variables
        query     = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

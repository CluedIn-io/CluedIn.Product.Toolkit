function Set-CluedInExportTargetConfiguration {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the Export Target configuration settings

        .DESCRIPTION
        GraphQL Query: Sets the Export Target configuration settings

        .PARAMETER Id
        This is the Id of the export target you want to update. It's not the be confused with the connectId a.k.a providerId

        .PARAMETER Configuration
        This is the PSCustomObject from the source material for the configuration property

        .EXAMPLE
        PS> Set-CluedInExportTargetConfiguration -ConnectorId '87e51d3c-a0fa-4c7e-aa62-68d2ec1c3f35' -AuthInfo $AuthInfo

        Sets Export Target Configuration to desired state
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id,
        [Parameter(Mandatory)][string]$AccountDisplay,
        [PSCustomObject]$Configuration
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveConnectorConfiguration'

    $query = @{
        variables = @{
            connectorConfiguration = @{
                id = $Id
                accountDisplay = $AccountDisplay
                helperConfiguration = $Configuration
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
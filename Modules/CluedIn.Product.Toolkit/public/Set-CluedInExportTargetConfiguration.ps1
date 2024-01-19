function Set-CluedInExportTargetConfiguration {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the Export Target configuration settings

        .DESCRIPTION
        GraphQL Query: Sets the Export Target configuration settings

        .EXAMPLE
        PS> Set-CluedInExportTargetConfiguration -ConnectorId '87e51d3c-a0fa-4c7e-aa62-68d2ec1c3f35' -AuthInfo $AuthInfo

        Sets Export Target Configuration to desired state
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$ConnectorId,
        [PSCustomObject]$AuthInfo
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveConnectorConfiguration'

    $query = @{
        variables =@{
            connectorConfiguration = @{
                id = $ConnectorId
                configuration = $AuthInfo
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
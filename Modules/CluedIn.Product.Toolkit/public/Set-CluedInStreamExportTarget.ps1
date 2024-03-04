function Set-CluedInStreamExportTarget {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a streams export target configuration

        .DESCRIPTION
        GraphQL Query: Sets a streams export target configuration

        .PARAMETER Id
        This is the guid Id of the stream being updated

        .PARAMETER Object
        This is a Stream object obtained from Get-CluedInStream. It must be passed in full.

        .EXAMPLE
        PS> Set-CluedInStream -Id 'ac1abbc4-cd21-442c-a89d-af5a5bc6813e' -Object $StreamObject
    #>

    param(
        [guid]$Id,
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'setupConnectorStream'

    if (!$Object.connector) { Write-Warning "No export target configured."; return }

    $query = @{
        variables =@{
            streamId = $Id
            exportConfiguration = @{
                connectorProviderDefinitionId = $Object.connector.Id
                containerName = $Object.containerName
                mode = $Object.mode
                exportOutgoingEdges = $Object.exportOutgoingEdges
                exportIncomingEdges = $Object.exportIncomingEdges
                dataTypes = @(
                    $Object.mappingConfiguration.ForEach({
                        @{
                            key = $_.sourceDataType
                            type = $_.sourceObjectType
                        }
                    })
                )
            }
        }

        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
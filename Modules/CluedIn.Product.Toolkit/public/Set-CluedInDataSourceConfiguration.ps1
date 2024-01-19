function Set-CluedInDataSourceConfiguration {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the quality configuration against a Data Source

        .DESCRIPTION
        GraphQL Query: Sets the quality configuration against a Data Source

        .EXAMPLE
        PS> Set-CluedInDataSourceConfiguration -Object $CustomObject
    #>

    [CmdletBinding()]
    param(
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveConnectorConfiguration'

    $query = @{
        variables =@{
            connectorConfiguration = @{
                id = $Object.id
                helperConfiguration = @{
                    EndpointName = $Object.name
                    DataSourceId = $Object.configuration.DataSourceId
                }
                source = $Object.source
                sourceQuality = $Object.sourceQuality
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
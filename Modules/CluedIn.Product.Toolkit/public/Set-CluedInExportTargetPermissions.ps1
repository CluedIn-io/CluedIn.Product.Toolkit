function Set-CluedInExportTargetPermissions {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the Export Target permissions

        .DESCRIPTION
        GraphQL Query: Sets the Export Target permissions

        .PARAMETER ConnectorId
        This is the Id of the connector where permissions are to be set.

        .PARAMETER UserId
        This is the id(s) of the users being granted to this export target

        .EXAMPLE
        PS> Set-CluedInExportTargetPermissions -ConnectorId '87e51d3c-a0fa-4c7e-aa62-68d2ec1c3f35' -UserId @('653ba074-b932-49af-9a50-d39eb63ba726', '05f86861-1614-4736-bc51-69041feb9e01')

        Grants permissions to the two user ids listed above against the specified connector
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$ConnectorId,
        [Parameter(Mandatory)][string[]]$UserId
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'grantUsersPermission'

    $query = @{
        variables = @{
            connectorId = $ConnectorId
            userIds = $UserId
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
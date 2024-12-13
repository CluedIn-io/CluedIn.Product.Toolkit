# Set-CluedInExportTargetStatusToPaused.ps1

function Set-CluedInExportTargetStatusToPaused {
    <#
        .SYNOPSIS
        GraphQL Mutation: Sets the Export Target status to "Paused"

        .DESCRIPTION
        This function sends a GraphQL mutation to update the status of a specified Export Target to "Paused".

        .PARAMETER ProviderId
        The unique identifier (GUID) of the provider associated with the Export Target.

        .PARAMETER ConnectorId
        The unique identifier (GUID) of the connector associated with the Export Target.

        .PARAMETER AccountId
        The account identifier as a string.

        .EXAMPLE
        PS> Set-CluedInExportTargetStatusToPaused -ProviderId 'f6178e19-7168-449c-b4b6-f9810e86c1c2' -ConnectorId 'a7fc8543-d483-422d-93b6-c283c1cae5ff' -AccountId '12314'

        Sets the status of the specified Export Target to "Paused".
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Guid]$ProviderId,

        [Parameter(Mandatory = $true)]
        [Guid]$ConnectorId,

        [Parameter(Mandatory = $true)]
        [string]$AccountId
    )

    # Retrieve the GraphQL mutation query content
    $queryContent = Get-CluedInGQLQuery -OperationName 'pauseConnectorConfiguration'

    # Construct the variables for the GraphQL mutation
    $variables = @{
        providerId  = $ProviderId
        connectorId = $ConnectorId
        accountId   = $AccountId
    }

    # Build the complete query payload
    $query = @{
        variables = $variables
        query     = $queryContent
    }

    # Invoke the GraphQL mutation and return the response
    return Invoke-CluedInGraphQL -Query $query
}

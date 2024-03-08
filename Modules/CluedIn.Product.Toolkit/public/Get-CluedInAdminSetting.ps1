function Get-CluedInAdminSetting {
    <#
        .SYNOPSIS
        GraphQL Query: Gets the Administrators Settings of the currently connected endpoint.

        .DESCRIPTION
        GraphQL Query: Gets the Administrators Settings of the currently connected endpoint.

        .EXAMPLE
        PS> Get-CluedInAdminSetting
    #>

    [CmdletBinding()]
    param()

    $id = (Get-CluedInCurrentOrganization).data.administration.organization.id
    $queryContent = Get-CluedInGQLQuery -OperationName 'getConfigurationSettings'

    $query = @{
        variables = @{
            id = $id
            includeHiddenFromUi = $true
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
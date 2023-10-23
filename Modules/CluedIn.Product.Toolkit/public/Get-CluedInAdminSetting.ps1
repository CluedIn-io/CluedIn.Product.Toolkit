function Get-CluedInAdminSetting {
    <#
        .SYNOPSIS
        GraphQL Query: Gets the Administrators Settings of the currently connected endpoint.

        .DESCRIPTION
        GraphQL Query: Gets the Administrators Settings of the currently connected endpoint.

        Utilises a few helper functions and also uses the env variable with the endpoint set.

        .EXAMPLE
        PS> Get-CluedInAdminSetting

        This will query the endpoint with a GraphQL body and return a powershell object which contains data you can use.
    #>

    [CmdletBinding()]
    param()

    $id = (Get-CluedInCurrentOrganisation).data.administration.organization.id
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
function Set-CluedInAdminSettings {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a specified admin settings

        .DESCRIPTION
        GraphQL Query: Sets a specified admin settings

        .EXAMPLE
        PS> Set-CluedInAdminSettings
    #>

    [CmdletBinding()]
    param(
        $AdminSettingName,
        $AdminSettingValue
    )

    $id = (Get-CluedInCurrentOrganisation).data.administration.organization.id

    $queryContent = Get-CluedInGQLQuery -OperationName 'changeConfigurationSettings'

    $query = @{
        variables =@{
            organizationId = $id
            key = $AdminSettingName
            value = $AdminSettingValue
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
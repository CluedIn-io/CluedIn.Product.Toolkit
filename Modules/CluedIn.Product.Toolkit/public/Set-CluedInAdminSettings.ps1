function Set-CluedInAdminSettings {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a specified admin settings

        .DESCRIPTION
        GraphQL Query: Sets a specified admin settings

        .PARAMETER Name
        This is the Key of an admin setting that you want to set.

        .PARAMETER Value
        This is the Value of an admin setting key that you want to set.

        .EXAMPLE
        PS> Set-CluedInAdminSettings -Name 'EnableTurboMode' -Value 'True'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Value
    )

    $id = (Get-CluedInCurrentOrganization).data.administration.organization.id

    $queryContent = Get-CluedInGQLQuery -OperationName 'changeConfigurationSettings'

    $query = @{
        variables =@{
            organizationId = $id
            key = $Name
            value = $Value
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
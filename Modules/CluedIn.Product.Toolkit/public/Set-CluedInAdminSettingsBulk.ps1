function Set-CluedInAdminSettingsBulk {
    <#
        .SYNOPSIS
        Performs the bulk update of all admin settings in version 4.4.0.

        .DESCRIPTION
        Uses the `updateConfigurationSettings` mutation, expects a hashtable of key/value pairs:

        .PARAMETER SettingsToApply
        A hashtable where each key is the setting name (configurationKey) and the value is the setting's new value.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$SettingsToApply
    )

    if ($env:CLUEDIN_CURRENTVERSION -ne "4.4.0") {
        Write-Host "Bulk update is only applicable to version 4.4.0." -ForegroundColor Yellow
        return
    }

    if (-not $SettingsToApply -or $SettingsToApply.Count -eq 0) {
        Write-Host "No admin settings to bulk update." -ForegroundColor Cyan
        return
    }

    # Get Organization ID
    $id = (Get-CluedInCurrentOrganization).data.administration.organization.id

    # Construct the settings array expected by the mutation
    $settingsArray = @()
    foreach ($key in $SettingsToApply.Keys) {
        $settingsArray += [pscustomobject]@{
            configurationKey = $key
            value            = $SettingsToApply[$key]
            useDefault       = $false
        }
    }

    $model = @{
        settings = $settingsArray
    }

    # Get the GraphQL query for bulk updates
    $queryContent = Get-CluedInGQLQuery -OperationName 'updateConfigurationSettings'
    $query = @{
        variables = @{
            organizationId = $id
            model          = $model
        }
        query = $queryContent
    }

    # Invoke the GraphQL mutation and return the result without internal error checking
    return Invoke-CluedInGraphQL -Query $query
}

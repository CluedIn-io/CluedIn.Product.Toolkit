function Import-Settings{
    <#
        .SYNOPSIS
        Imports deduplication projects

        .DESCRIPTION
        Imports deduplication projects

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-Rules -RestorePath "c:\backuplocation"

        This will import all of the export targets
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )

    $adminSettingsPath = Join-Path -Path $RestorePath -ChildPath 'General/AdminSetting.json'
    if (Test-Path -Path $adminSettingsPath -PathType Leaf) {
        Write-Host "INFO: Importing Admin Settings" -ForegroundColor 'Green'
        $restoreAdminSetting = Get-Content -Path $adminSettingsPath | ConvertFrom-Json -Depth 20

        $settings = ($restoreAdminSetting.data.administration.configurationSettings).psobject.properties.name
        $currentSettings = (Get-CluedInAdminSetting).data.administration.configurationSettings

        $settingsToUpdate = @{}

        foreach ($setting in $settings) {
            $key = $setting

            if ($key -notin $currentSettings.psobject.properties.name) {
                Write-Verbose "Skipping '$key' as it's not a current setting"
                continue
            }

            $newValue = $restoreAdminSetting.data.administration.configurationSettings.$key
            $currentValue = $currentSettings.$key

            # Determine if the value has changed
            $hasChanged = $newValue -ne $currentValue

            $settingsToUpdate[$key] = $newValue

            if ($hasChanged) {
                Write-Host "Processing Admin Setting '$key'. Was: $currentValue, Now: $newValue" -ForegroundColor 'Cyan'
            }
        }

        if ($settingsToUpdate.Count -gt 0) {
            Write-Host "INFO: Performing bulk update of admin settings..." -ForegroundColor 'Cyan'
            $bulkResult = Set-CluedInAdminSettingsBulk -SettingsToApply $settingsToUpdate
            Check-ImportResult($bulkResult)
        }
    }
}
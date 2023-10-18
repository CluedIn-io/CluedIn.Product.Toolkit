<#
    .SYNOPSIS
    Imports configuration to the connected environment by using backups

    .DESCRIPTION
    Imports configuration to the connected environment by using backups

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL

    .PARAMETER Organisation

    .PARAMETER Version

    .PARAMETER BackupPath

    .EXAMPLE
    PS> ./Export-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organisation 'dev' -Version '2023.07'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][string]$Organisation,
    [Parameter(Mandatory)][version]$Version,
    [Parameter(Mandatory)][string]$RestorePath = 'C:\.dev\EXPORTTEST'
)

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO: Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation -Version $Version

Write-Host "INFO: Starting import"

Write-Host "INFO: Importing Admin Settings"
$generalPath = Join-Path -Path $BackupPath -ChildPath 'General'
if (!(Test-Path -Path $generalPath -PathType Container)) { throw "'$generalPath' could not be found. Please investigate" }
$adminSetting = Get-Content -Path (Join-Path -Path $generalPath -ChildPath 'AdminSetting.json') | ConvertFrom-Json

$settings = ($adminSetting.data.administration.configurationSettings).psobject.properties.name

foreach ($setting in $settings) {
    # We apparently export API keys which need to be re-imported.
    # Need to find out where these are grabbed from and we can then store/retrieve from KV

    $key = $setting
    $value = $adminSetting.data.administration.configurationSettings.$key

    Set-CluedInAdminSettings -AdminSettingName $key -AdminSettingValue $value
}

Write-Host "INFO: Importing Vocabularies"

Write-Host "INFO: Importing Vocabulary Keys"

Write-Host "INFO: Importing Data Source Sets"

Write-Host "INFO: Importing Data Sources"

Write-Host "INFO: Importing Data Sets"
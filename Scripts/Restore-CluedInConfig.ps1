<#
    .SYNOPSIS
    Restores configuration to the connected environment by using backups

    .DESCRIPTION
    Restores configuration to the connected environment by using backups

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
    [Parameter(Mandatory)][string]$BackupPath = 'C:\.dev\EXPORTTEST'
)

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO - Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation -Version $Version

Write-Host "INFO - Starting restore"


# Restore Admin Settings

$adminSettings = Get-Content "$PSScriptRoot\BackupFiles\Settings.json" | ConvertFrom-Json
$Settings = $BackupFile.data.administration.configurationSettings

foreach ( $Setting in $Settings.psobject.properties.name ) {
    $AdminSettingName = ""
    $AdminSettingValue = ""

    $AdminSettingName = $Setting.replace('.','-')
    $KVEntry = Get-AzKeyVaultSecret -VaultName "ABA-DEV-IMPL-KV-001" -Name $AdminSettingName -AsPlainText
  
    $Query = SetAdminSettingsQuery -ActiveOrg $Config['OrgId'] -AdminSettingName $Setting  -AdminSettingValue $KVEntry

    Get-CI-Data -baseURL $_baseURL -token $Token -GQlQuery $Query 
}

# Restore Vocab and Keys
$VocabBackups = Get-ChildItem -Path  "$PSScriptRoot\BackupFiles\Vocabs\" -Filter VOC-*


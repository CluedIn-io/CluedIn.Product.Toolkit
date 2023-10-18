<#
        .SYNOPSIS
        Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

        .DESCRIPTION
        Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

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
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation

Write-Host "INFO - Starting backup"
Get-CluedInAdminSetting | Out-JsonFile -Path $BackupPath -Name 'AdminSetting'
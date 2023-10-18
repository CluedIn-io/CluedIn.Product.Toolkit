<#
        .SYNOPSIS
        Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

        .DESCRIPTION
        Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

        It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

        .EXAMPLE
        PS> ./Export-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organisation 'dev' -Version '2023.07'
    #>

[CmdletBinding()]
param(
    [string]$BaseURL,
    [string]$Organisation,
    [version]$Version
)

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO - Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation
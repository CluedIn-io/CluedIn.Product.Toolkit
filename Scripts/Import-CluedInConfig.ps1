<#
    .SYNOPSIS
    Imports configuration to the connected environment by using backups

    .DESCRIPTION
    Imports configuration to the connected environment by using backups

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL
    This is the base url of your clued in instance. If you access CluedIn by https://cluedin.domain.com, the BaseURL is 'domain.com'

    .PARAMETER Organization
    This is the section before your base URL. If you access CluedIn by https://cluedin.domain.com, the Organization is 'cluedin'

    .PARAMETER RestorePath
    This is the location of the export files ran by Export-CluedInConfig

    .PARAMETER IncludeSupportFiles
    Exports a transcript along with the produced JSON files for CluedIn support to use to diagnose any issues relating to migration.

    .EXAMPLE
    PS> ./Import-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organization 'dev' -RestorePath /path/to/backups
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][Alias('Organisation')][string]$Organization,
    [Parameter(Mandatory)][string]$RestorePath,
    [switch]$UseHTTP,
    [switch]$IncludeSupportFiles
)

if ($IncludeSupportFiles) {
    $tempExportDirectory = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath (Get-Date -Format "yyyyMMdd_HHmmss_clue\din")
    $supportFile = Join-Path -Path $tempExportDirectory -ChildPath ('transcript_{0}.txt' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    New-Item -Path $tempExportDirectory -ItemType Directory | Out-Null

    Write-Host "INFO: Dumping support files"
    Start-Transcript -Path $supportFile | Out-Null
}

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO: Connecting to 'https://$Organization.$BaseURL'"
Connect-CluedInOrganization -BaseURL $BaseURL -Organization $Organization -UseHTTP:$UseHTTP

Import-Settings -RestorePath $RestorePath

Import-Glossaries -RestorePath $RestorePath

$lookupVocabularies = Import-Vocabularies -RestorePath $RestorePath

Import-VocabularyKeys -RestorePath $RestorePath -LookupVocabularies $lookupVocabularies

Import-DataSources -RestorePath $RestorePath

Import-DataSets -RestorePath $RestorePath

Import-Rules -RestorePath $RestorePath

$lookupConnectors = Import-ExportTargets -RestorePath $RestorePath

Import-Streams -RestorePath $RestorePath -LookupConnectors $lookupConnectors

Import-CleanProjects -RestorePath $RestorePath

Import-DeduplicationProjects -RestorePath $RestorePath

Write-Host "INFO: Import Complete" -ForegroundColor 'Green'

if ($IncludeSupportFiles) {
    Write-Verbose "Copying JSON to support directory"
    Copy-Item -Path "$RestorePath/*" -Recurse -Destination $tempExportDirectory
    Stop-Transcript | Out-Null

    $zippedArchive = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('cluedin-support_{0}.zip' -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    Compress-Archive -Path "$tempExportDirectory" -DestinationPath "$zippedArchive" -Force
    Remove-Item -Path $tempExportDirectory -Recurse -Force

    Write-Host "Support files ready for sending '$zippedArchive'"
}



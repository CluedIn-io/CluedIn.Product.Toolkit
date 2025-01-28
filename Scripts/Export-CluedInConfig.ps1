<#
    .SYNOPSIS
    Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

    .DESCRIPTION
    Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL
    This is the base url of your clued in instance. If you access CluedIn by https://cluedin.domain.com, the BaseURL is 'domain.com'

    .PARAMETER Organization
    This is the section before your base URL. If you access CluedIn by https://cluedin.domain.com, the Organization is 'cluedin'

    .PARAMETER BackupPath
    This is the location of where to export files

    .PARAMETER SelectVocabularies
    This is a list of vocabularies (along with keys) that automatically get backed up.
    The guid or name of the vocabulary must be specified in a comma separated string.

    Example: '66505aa1-bacb-463e-832c-799c484577a8,e257a226-d91c-4946-a8af-85ef803cf55e,organization,user'

    .PARAMETER SelectDataSets
    This is a list of Data Sets to backup.
    Default value is 'None', but 'All' and ints are accepted in csv format wrapped in a string.

    Example: '1, 2, 3'

    .PARAMETER SelectRules
    This is a list of Rules to backup. It's agnostic as to what type of rules so long as you specify the guid.
    Default value is 'None', but 'All' and guids are accepted in csv format wrapped in a string.

    Example: '66505aa1-bacb-463e-832c-799c484577a8, e257a226-d91c-4946-a8af-85ef803cf55e'

    .PARAMETER SelectExportTargets
    This is a list of Export Targets to backup. It supports All, None, and csv format of the Id's

    .PARAMETER SelectStreams
    This is a list of Streams to backup. It supports All, None, and csv format of the Id's

    .PARAMETER SelectGlossaries
    This is what Glossaries to export. It supports All, None, and csv format of the Id's.
    It will export all Glossary terms along with it as well.

    .PARAMETER SelectCleanProjects
    Specifies what Clean Projects to export. It supports All, None, and csv format of the Id's

    .PARAMETER SelectDeduplicationProjects
    Specifies what Deduplication Projects to export. It supports All, None, and csv format of the Id's

    .PARAMETER IncludeSupportFiles
    Exports a transcript along with the produced JSON files for CluedIn support to use to diagnose any issues relating to migration.

    .EXAMPLE
    PS> ./Export-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organization 'dev'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][Alias('Organisation')][string]$Organization,
    [Parameter(Mandatory)][string]$BackupPath,
    [switch]$UseHTTP,
    [switch]$BackupAdminSettings,
    [string]$SelectVocabularies = 'None',
    [string]$SelectDataSets = 'None',
    [string]$SelectRules = 'None',
    [string]$SelectExportTargets = 'None',
    [string]$SelectStreams = 'None',
    [string]$SelectGlossaries = 'None',
    [string]$SelectCleanProjects = 'None',
    [string]$SelectDeduplicationProjects = 'None',
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

Write-Host "INFO: Starting backup"

Export-Settings -BackupPath $BackupPath -BackupAdminSettings:$BackupAdminSettings

$dataSourceSets = Export-DataSourceSets -BackupPath $BackupPath

Export-DataSets -BackupPath $BackupPath -SelectDataSets $SelectDataSets -DataSourceSets $dataSourceSets

Export-Vocabularies -BackupPath $BackupPath -SelectVocabularies $SelectVocabularies

Export-Rules -BackupPath $BackupPath -SelectRules $SelectRules

Export-ExportTargets -BackupPath $BackupPath -SelectExportTargets $SelectExportTargets

Export-Streams -BackupPath $BackupPath -SelectStreams $SelectStreams

Export-Glossaries -BackupPath $BackupPath -SelectGlossaries $SelectGlossaries

Export-CleanProjects -BackupPath $BackupPath -SelectCleanProjects $SelectCleanProjects

Export-DeduplicationProjects -BackupPath $BackupPath -SelectDeduplicationProjects $SelectDeduplicationProjects 

Write-Host "INFO: Backup now complete"

if ($IncludeSupportFiles) {
    Write-Verbose "Copying exported JSON to support directory"
    Copy-Item -Path "$BackupPath/*" -Recurse -Destination $tempExportDirectory
    Stop-Transcript | Out-Null

    $zippedArchive = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('cluedin-support_{0}.zip' -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    Compress-Archive -Path "$tempExportDirectory" -DestinationPath "$zippedArchive" -Force
    Remove-Item -Path $tempExportDirectory -Recurse -Force

    Write-Host "Support files ready for sending '$zippedArchive'"
}
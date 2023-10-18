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
    [Parameter()][string]$BackupPath = 'C:\.dev\EXPORTTEST'
)

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO - Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation -Version $Version

Write-Host "INFO - Starting backup"

Write-Host "INFO - Exporting Admin Settings"
$generalPath = Join-Path -Path $BackupPath -ChildPath 'General'
if (!(Test-Path -Path $generalPath -PathType Container)) { New-Item $generalPath -ItemType Directory | Out-Null }
Get-CluedInAdminSetting | Out-JsonFile -Path $generalPath -Name 'AdminSetting'

Write-Host "INFO - Exporting Data Source Sets"
$path = Join-Path -Path $BackupPath -ChildPath 'Data/SourceSets'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }
$dataSourceSets = Get-CluedInDataSourceSet
$dataSourceSets | Out-JsonFile -Path $path -Name 'DataSourceSet'

Write-Host "INFO - Exporting Data Sources"
$path = Join-Path -Path $BackupPath -ChildPath 'Data/Sources'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }
$dataSources = $dataSourceSets.data.inbound.dataSourceSets.data.datasources
$dataSetProcess = @()
for ($i = 0; $i -lt $dataSources.count; $i++) {
    $dataSource = Get-CluedInDataSource -Id $dataSources[$i].id
    $dataSource | Out-JsonFile -Path $path -Name ('{0}-DataSource' -f $i)
    $dataSetProcess += @{
        id = $dataSource.data.inbound.datasource.datasets.id
        type = $dataSource.data.inbound.datasource.type
    }
}

Write-Host "INFO - Exporting Data Sets"
$path = Join-Path -Path $BackupPath -ChildPath 'Data/Sets'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }
foreach ($dataSet in $dataSetProcess) {
    Get-CluedInDataSet -id $dataSet.id | Out-JsonFile -Path $path -Name ('{0}-DataSet' -f $dataSet.id)
    if ($dataSet.type -eq 'file') {
        Get-CluedInDataSetContent -id $dataSet.id | Out-JsonFile -Path $path -Name ('{0}-DataSetContent' -f $dataSet.id)
    }
}

Write-Host "INFO - Exporting Vocabularies and Keys"


Write-Host "INFO - Backup now complete"
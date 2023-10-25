<#
    .SYNOPSIS
    Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

    .DESCRIPTION
    Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL
    This is the base url used to access the environment. It should not contain http(s)

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
    [Parameter(Mandatory)][string]$BackupPath
)

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO: Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation -Version $Version

Write-Host "INFO: Starting backup"

# Settings
Write-Host "INFO: Exporting Admin Settings"
$generalPath = Join-Path -Path $BackupPath -ChildPath 'General'
if (!(Test-Path -Path $generalPath -PathType Container)) { New-Item $generalPath -ItemType Directory | Out-Null }
Get-CluedInAdminSetting | Out-JsonFile -Path $generalPath -Name 'AdminSetting'

# Data Sources
Write-Host "INFO: Exporting Data Source Sets"
$path = Join-Path -Path $BackupPath -ChildPath 'Data/SourceSets'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }
$dataSourceSets = Get-CluedInDataSourceSet
$dataSourceSets | Out-JsonFile -Path $path -Name 'DataSourceSet'

Write-Host "INFO: Exporting Data Sources"
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

Write-Host "INFO: Exporting Data Sets and Annotations"
$path = Join-Path -Path $BackupPath -ChildPath 'Data/Sets'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }
foreach ($dataSet in $dataSetProcess) {
    $set = Get-CluedInDataSet -id $dataSet.id
    $set | Out-JsonFile -Path $path -Name ('{0}-DataSet' -f $dataSet.id)
    if ($dataSet.type -eq 'file') {
        Get-CluedInDataSetContent -id $dataSet.id | Out-JsonFile -Path $path -Name ('{0}-DataSetContent' -f $dataSet.id)
    }

    Write-Verbose "INFO: Exporting Annotation"
    $annotationId = $set.data.inbound.dataSet.annotationId
    Get-CluedInAnnotations -id $annotationId | Out-JsonFile -Path $path -Name ('{0}-Annotation' -f $dataSet.id)
}

# Vocabulary
Write-Host "INFO: Exporting Vocabularies"
$dataCatalogPath = Join-Path -Path $BackupPath -ChildPath 'DataCatalog'
$vocabPath = Join-Path -Path $dataCatalogPath -ChildPath 'Vocab'
if (!(Test-Path -Path $vocabPath -PathType Container)) { New-Item $vocabPath -ItemType Directory | Out-Null }
$vocabularies = Get-CluedInVocabulary -IncludeCore
$customVocabularies = $vocabularies.data.management.vocabularies.data |
    Where-Object {$_.isCluedInCore -eq $False}
$vocabularies | Out-JsonFile -Path $dataCatalogPath -Name 'VocabulariesManifest'
foreach ($vocab in $customVocabularies) {
    Get-CluedInVocabularyById -Id $vocab.vocabularyId | Out-JsonFile -Path $vocabPath -Name $vocab.vocabularyId
}

Write-Host "INFO: Exporting Vocabulary Keys"
$vocabKeysPath = Join-Path -Path $dataCatalogPath -ChildPath 'Keys'
if (!(Test-Path -Path $vocabKeysPath -PathType Container)) { New-Item $vocabKeysPath -ItemType Directory | Out-Null }
foreach ($i in $vocabularies.data.management.vocabularies.data.vocabularyId) {
    Get-CluedInVocabularyKey -Id $i | Out-JsonFile -Path $vocabKeysPath -Name $i
}

# Rules
Write-Host "INFO: Exporting Rules"
$rulesPath = Join-Path -Path $BackupPath -ChildPath 'Rules'
$dataPartRulesPath = Join-Path -Path $rulesPath -ChildPath 'DataPart'
$survivorshipRulesPath = Join-Path -Path $rulesPath -ChildPath 'Survivorship'
$goldenRecordsRulesPath = Join-Path -Path $rulesPath -ChildPath 'GoldenRecords'
if (!(Test-Path -Path $rulesPath -PathType Container)) {
    New-Item $dataPartRulesPath -ItemType Directory | Out-Null
    New-Item $survivorshipRulesPath -ItemType Directory | Out-Null
    New-Item $goldenRecordsRulesPath -ItemType Directory | Out-Null
}

$scope = 'Survivorship'
$survivorshipRules = Get-CluedInRules -Scope $scope
#$survivorshipRules | Out-JsonFile -Path $survivorshipRulesPath -Name 'SurvivorshipRules'
if ($survivorshipRules.data.management.rules.total -ge 1) {
    foreach ($rule in $survivorshipRules.data.management.rules.data) {
        Get-CluedInRules -Id $rule.id -Scope $scope | Out-JsonFile -Path $survivorshipRulesPath -Name $rule.id
    }
}

$scope = 'DataPart'
$dataPartRules = Get-CluedInRules -Scope $scope
#$dataPartRules | Out-JsonFile -Path $dataPartRulesPath -Name 'DataPartRules'
if ($dataPartRules.data.management.rules.total -ge 1) {
    foreach ($rule in $dataPartRules.data.management.rules.data) {
        Get-CluedInRules -Id $rule.id -Scope $scope | Out-JsonFile -Path $dataPartRulesPath -Name $rule.id
    }
}

$scope = 'Entity'
$goldenRecordRules = Get-CluedInRules -Scope $scope
#$goldenRecordRules | Out-JsonFile -Path $goldenRecordsRulesPath -Name 'GoldenRecordRules'
if ($goldenRecordRules.data.management.rules.total -ge 1) {
    foreach ($rule in $goldenRecordRules.data.management.rules.data) {
        Get-CluedInRules -Id $rule.id -Scope $scope | Out-JsonFile -Path $goldenRecordsRulesPath -Name $rule.id
    }
}

Write-Host "INFO: Backup now complete"
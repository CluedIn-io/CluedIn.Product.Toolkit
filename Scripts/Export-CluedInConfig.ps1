<#
    .SYNOPSIS
    Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

    .DESCRIPTION
    Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL
    This is the base url of your clued in instance. If you access CluedIn by https://cluedin.domain.com, the BaseURL is 'domain.com'

    .PARAMETER Organisation
    This is the section before your base URL. If you access CluedIn by https://cluedin.domain.com, the Organisation is 'cluedin'

    .PARAMETER Version
    This is the version of your current CluedIn environment in the format of '2023.01'

    .PARAMETER BackupPath
    This is the location of where to export files

    .EXAMPLE
    PS> ./Export-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organisation 'dev' -Version '2023.07'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][string]$Organisation,
    [Parameter(Mandatory)][version]$Version,
    [Parameter(Mandatory)][string]$BackupPath,
    [string]$SelectVocabularies = 'None',
    [string]$SelectDataSources = 'None',
    [string]$SelectDataSets = 'None',
    [string]$SelectRules = 'None'
)

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO: Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation -Version $Version

Write-Host "INFO: Starting backup"

# Settings
$generalPath = Join-Path -Path $BackupPath -ChildPath 'General'
if (!(Test-Path -Path $generalPath -PathType Container)) { New-Item $generalPath -ItemType Directory | Out-Null }

Write-Host "INFO: Exporting Admin Settings" -ForegroundColor 'Green'
Get-CluedInAdminSetting | Out-JsonFile -Path $generalPath -Name 'AdminSetting'

# Data Source Sets
$path = Join-Path -Path $BackupPath -ChildPath 'Data/SourceSets'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }

Write-Host "INFO: Exporting Data Source Sets" -ForegroundColor 'Green'
$dataSourceSets = Get-CluedInDataSourceSet
$dataSourceSets | Out-JsonFile -Path $path -Name 'DataSourceSet'

# Data Sources
$path = Join-Path -Path $BackupPath -ChildPath 'Data/Sources'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }

$dataSources = $dataSourceSets.data.inbound.dataSourceSets.data.datasources

$dataSourceIds = switch ($SelectDataSources) {
    'All' { $dataSources.id }
    'None' { $null }
    default { ($SelectDataSources -Split ',').Trim() }
}

foreach ($id in $dataSourceIds) {
    Write-Verbose "Processing id: $id"
    $dataSource = Get-CluedInDataSource -Id $id
    if ((!$?) -or ($dataSource.errors)) { Write-Warning "Id '$id' was not found. This won't be backed up"; continue }

    Write-Host "Exporting Data Source: $($dataSource.data.inbound.dataSource.name) ($id)" -ForegroundColor 'Cyan'
    $dataSource | Out-JsonFile -Path $path -Name ('{0}-DataSource' -f $id)
}

# Data Sets and Annotations
$path = Join-Path -Path $BackupPath -ChildPath 'Data/Sets'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }

$dataSetIds = switch ($SelectDataSets) {
    'All' { $dataSources.dataSets.id }
    'None' { $null }
    default { ($SelectDataSets -Split ',').Trim() }
}

foreach ($id in $dataSetIds) {
    Write-Verbose "Processing id: $id"
    $set = Get-CluedInDataSet -id $id
    if ((!$?) -or ($set.errors)) { Write-Warning "Id '$id' was not found. This won't be backed up"; continue }

    Write-Host "Exporting Data Set: '$($set.data.inbound.dataSet.name) ($id)'" -ForegroundColor 'Cyan'
    $set | Out-JsonFile -Path $path -Name ('{0}-DataSet' -f $id)

    if ($set.data.inbound.dataSet.dataSource.type -eq 'file') {
        Get-CluedInDataSetContent -id $id | Out-JsonFile -Path $path -Name ('{0}-DataSetContent' -f $id)
    }

    Write-Verbose "Exporting Annotation"
    $annotationId = $set.data.inbound.dataSet.annotationId
    Get-CluedInAnnotations -id $annotationId | Out-JsonFile -Path $path -Name ('{0}-Annotation' -f $id)
}

# Vocabulary
$dataCatalogPath = Join-Path -Path $BackupPath -ChildPath 'DataCatalog'
$vocabPath = Join-Path -Path $dataCatalogPath -ChildPath 'Vocab'
if (!(Test-Path -Path $vocabPath -PathType Container)) { New-Item $vocabPath -ItemType Directory | Out-Null }

if ($SelectVocabularies -ne 'None') {
    $vocabularies = Get-CluedInVocabulary -IncludeCore
    Write-Host "INFO: Exporting Vocabularies and Keys" -ForegroundColor 'Green'
}

$vocabularyIds = switch ($SelectVocabularies) {
    'All' { ($vocabularies.data.management.vocabularies.data | Where-Object {$_.isCluedInCore -eq $False}).vocabularyId }
    'None' { $null }
    default { ($SelectVocabularies -Split ',').Trim() }
}

foreach ($id in $vocabularyIds) {
    $vocab = Get-CluedInVocabularyById -Id $id
    if ((!$?) -or ($vocab.errors)) { Write-Warning "Id '$id' was not found. This won't be backed up"; continue }

    Write-Host "Exporting Vocabulary: '$($vocab.data.management.vocabulary.vocabularyName) ($id)'" -ForegroundColor 'Cyan'
    $vocab | Out-JsonFile -Path $vocabPath -Name $id
}

$vocabKeysPath = Join-Path -Path $dataCatalogPath -ChildPath 'Keys'
if (!(Test-Path -Path $vocabKeysPath -PathType Container)) { New-Item $vocabKeysPath -ItemType Directory | Out-Null }

foreach ($id in $vocabularyIds) { # Should we move this into above block if we can't seperate?
    Write-Verbose "Processing id: $id"
    Write-Host "Exporting Vocabulary Keys" -ForegroundColor 'Cyan'
    $vocabKey = Get-CluedInVocabularyKey -Id $id
    if ((!$?) -or ($vocabKey.errors)) { Write-Warning "Id '$id' was not found. This won't be backed up"; continue }
    $vocabKey | Out-JsonFile -Path $vocabKeysPath -Name $id
}

# Rules
if ($SelectRules -eq 'All') {
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
    if ($survivorshipRules.data.management.rules.total -ge 1) {
        foreach ($rule in $survivorshipRules.data.management.rules.data) {
            Get-CluedInRules -Id $rule.id -Scope $scope | Out-JsonFile -Path $survivorshipRulesPath -Name $rule.id
        }
    }

    $scope = 'DataPart'
    $dataPartRules = Get-CluedInRules -Scope $scope
    if ($dataPartRules.data.management.rules.total -ge 1) {
        foreach ($rule in $dataPartRules.data.management.rules.data) {
            Get-CluedInRules -Id $rule.id -Scope $scope | Out-JsonFile -Path $dataPartRulesPath -Name $rule.id
        }
    }

    $scope = 'Entity'
    $goldenRecordRules = Get-CluedInRules -Scope $scope
    if ($goldenRecordRules.data.management.rules.total -ge 1) {
        foreach ($rule in $goldenRecordRules.data.management.rules.data) {
            Get-CluedInRules -Id $rule.id -Scope $scope | Out-JsonFile -Path $goldenRecordsRulesPath -Name $rule.id
        }
    }
}

Write-Host "INFO: Backup now complete"
<#
    .SYNOPSIS
    Validates the configuration before the import process

    .DESCRIPTION
    Validates the configuration before the import stage, allowing the user of the script or pipeline to cancel before it processes.

    .PARAMETER BaseURL
    This is the base url of your clued in instance. If you access CluedIn by https://cluedin.domain.com, the BaseURL is 'domain.com'

    .PARAMETER Organisation
    This is the section before your base URL. If you access CluedIn by https://cluedin.domain.com, the Organisation is 'cluedin'

    .PARAMETER Version
    This is the version of your current CluedIn environment in the format of '2023.01'

    .PARAMETER RestorePath
    This is the location of the export files ran by Export-CluedInConfig

    .EXAMPLE
    PS> ./Confirm-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organisation 'dev' -Version '2023.07' -RestorePath /path/to/backups
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][string]$Organisation,
    [Parameter(Mandatory)][version]$Version,
    [Parameter(Mandatory)][string]$RestorePath
)

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO: Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation -Version $Version

# Variables
Write-Verbose "Setting Script Variables"
$dataCatalogPath = Join-Path -Path $RestorePath -ChildPath 'DataCatalog'
$vocabPath = Join-Path -Path $dataCatalogPath -ChildPath 'Vocab'
$vocabKeysPath = Join-Path -Path $dataCatalogPath -ChildPath 'Keys'
$dataPath = Join-Path -Path $RestorePath -ChildPath 'Data'
$dataSourceSetsPath = Join-Path -Path $dataPath -ChildPath 'SourceSets'
$dataSourcesPath = Join-Path -Path $dataPath -ChildPath 'Sources'
$dataSetsPath = Join-Path -Path $dataPath -ChildPath 'Sets'
$generalPath = Join-Path -Path $RestorePath -ChildPath 'General'
$rulesPath = Join-Path -Path $RestorePath -ChildPath 'Rules'

# Test Paths
if (!(Test-Path -Path $generalPath -PathType Container)) { throw "'$generalPath' could not be found. Please investigate" }
if (!(Test-Path -Path $vocabPath, $vocabKeysPath -PathType Container)) {
    throw "There as an issue finding '$vocabPath' or sub-folders. Please investigate"
}
if (!(Test-Path -Path $dataSourceSetsPath, $dataSourcesPath, $dataSetsPath -PathType Container)) {
    throw "There as an issue finding '$dataPath' or sub-folders. Please investigate"
}

# Settings
Write-Host "INFO: Comparing Admin Settings" -ForegroundColor 'Green'
$restoreAdminSetting = Get-Content -Path (Join-Path -Path $generalPath -ChildPath 'AdminSetting.json') | ConvertFrom-Json -Depth 20

$settings = ($restoreAdminSetting.data.administration.configurationSettings).psobject.properties.name
$currentSettings = (Get-CluedInAdminSetting).data.administration.configurationSettings

foreach ($setting in $settings) {
    $key = $setting
    $newValue = $restoreAdminSetting.data.administration.configurationSettings.$key
    $currentValue = $currentSettings.$key

    $operator = if ($newValue -ne $currentValue) { '~' } else { '=' }
    Write-Host "$operator ${setting} ($(if ($operator -eq '~') {$newValue}))"
}

# Vocabulary
Write-Host "INFO: Comparing Vocabularies" -ForegroundColor 'Green'
$restoreVocabularies = Get-ChildItem -Path $vocabPath -Filter "*.json"

foreach ($vocabulary in $restoreVocabularies) {
    $vocabJson = Get-Content -Path $vocabulary.FullName | ConvertFrom-Json -Depth 20
    $vocabObject = $vocabJson.data.management.vocabulary

    Write-Host "Processing Vocab: $($vocabObject.vocabularyName) ($($vocabObject.vocabularyId))" -ForegroundColor 'Cyan'

    $exists = (Get-CluedInVocabulary -Search $vocabObject.vocabularyName -HardMatch).data.management.vocabularies.data
    if (!$exists) {
        $operator = '+'
    }
    else {
        $operator = '~'
        if ($exists.count -ne 1) { Write-Warning "Issue with following:`n$exists. Only 1 should have been returned"; continue }
        $currentVocab = (Get-CluedInVocabularyById -Id $exists.vocabularyId).data.management.vocabulary
    }
    Write-Host "$operator $($vocabObject.vocabularyName)" -ForegroundColor 'Cyan'
    if ($operator -eq '~') {
        Write-Host "Current:`n$($currentVocab | Out-String)"
        Write-Host "Modified:`n$($vocabObject | Out-String)"
    }
}

Write-Host "INFO: Comparing Vocabulary Keys" -ForegroundColor 'Green'
$vocabKeys = Get-ChildItem -Path $vocabKeysPath -Filter "*.json"
foreach ($vocabKey in $vocabKeys) {
    $vocabKeyJson = Get-Content -Path $vocabKey.FullName | ConvertFrom-Json -Depth 20
    $vocabKeyObject = $vocabKeyJson.data.management.vocabularyKeysFromVocabularyId.data

    $vocabName = $vocabKeyObject.vocabulary.vocabularyName | Select-Object -First 1
    $vocabulary = Get-CluedInVocabulary -Search $vocabName -IncludeCore
    foreach ($key in $vocabKeyObject) {
        $currentVocabularyKey = Get-CluedInVocabularyKey -Search $key.key
        $currentVocabularyKeyObject = $currentVocabularyKey.data.management.vocabularyPerKey
        if (!$currentVocabularyKeyObject.key) { $operator = '+' }
        else { $operator = '~' }

        Write-Host "$operator $($currentVocabularyKeyObject.key)" -ForegroundColor 'Cyan'
        if ($operator -eq '~') {
            Write-Host "Current:`n$($currentVocabularyKeyObject | Out-String)"
            Write-Host "Modified:`n$($key | Out-String)"
        }
    }
}

Write-Host "INFO: Comparing Data Sources" -ForegroundColor 'Green'
$dataSources = Get-ChildItem -Path $dataSourcesPath -Filter "*.json"

foreach ($dataSource in $dataSources) {
    $dataSourceJson = Get-Content -Path $dataSource.FullName | ConvertFrom-Json -Depth 20
    $dataSourceObject = $dataSourceJson.data.inbound.dataSource
    $dataSourceSetName = $dataSourceObject.dataSourceSet.name

    $dataSourceSet = Get-CluedInDataSourceSet -Search $dataSourceSetName
    $dataSourceSetMatch = $dataSourceSet.data.inbound.dataSourceSets.data |
        Where-Object {$_.name -match "^$dataSourceSetName$"}
    if (!$dataSourceSetMatch) { $operator = '+' }
    else { $operator = '=' }

    Write-Host "$operator Data Source Set: $($dataSourceSet.data.inbound.dataSourceSets.data.name)" -ForegroundColor 'Cyan'

    $exists = (Get-CluedInDataSource -Search $dataSourceObject.name).data.inbound.dataSource
    if (!$exists) { $operator = '+' }
    else { $operator = '=' }

    Write-Host "$operator Data Source: $($dataSourceObject.name)" -ForegroundColor 'Cyan'
}

Write-Host "INFO: Comparing Data Sets" -ForegroundColor 'Green'
$dataSets = Get-ChildItem -Path $dataSetsPath -Filter "*-DataSet.json"

foreach ($dataSet in $dataSets) {
    $dataSetJson = Get-Content -Path $dataSet.FullName | ConvertFrom-Json -Depth 20
    $dataSetObject = $dataSetJson.data.inbound.dataSet

    $dataSource = Get-CluedInDataSource -Search $dataSetObject.dataSource.name
    $dataSetObject.dataSource.id = $dataSource.data.inbound.dataSource.id

    $exists = ($dataSetObject.name -in $dataSource.data.inbound.dataSource.dataSets.name)
    if (!$exists) { $operator = '+' }
    else {
        $existsDataSetObject = $dataSource.data.inbound.dataSource.dataSets |
            Where-Object {$_.name -eq $dataSetObject.name}
        $operator = '~'
    }

    Write-Host "$operator $($dataSetObject.name)" -ForegroundColor 'Cyan'
    if ($operator -eq '~') {
        Write-Host "Current:`n$($existsDataSetObject | Out-String)"
        Write-Host "Modified:`n$($dataSetObject | Out-String)"
    }
}

# Rules
Write-Host "INFO: Comparing Rules" -ForegroundColor 'Green'
$rules = Get-ChildItem -Path $rulesPath -Filter "*.json" -Recurse
foreach ($rule in $rules) {
    $ruleJson = Get-Content -Path $rule.FullName | ConvertFrom-Json -Depth 20
    $ruleObject = $ruleJson.data.management.rule

    $exists = Get-CluedInRules -Search $ruleObject.name -Scope $ruleObject.scope
    $existsRuleObject = $exists.data.management.rules.data
    if (!$existsRuleObject) { $operator = '+' }
    else { $operator = '~' }

    Write-Host "$operator $($ruleObject.name) ($($ruleObject.scope))" -ForegroundColor 'Cyan'
    if ($operator -eq '~') {
        Write-Host "Current:`n$($existsRuleObject | Out-String)"
        Write-Host "Modified:`n$($ruleObject | Out-String)"
    }
}

Write-Host "INFO: Import Complete" -ForegroundColor 'Green'
<#
    .SYNOPSIS
    Imports configuration to the connected environment by using backups

    .DESCRIPTION
    Imports configuration to the connected environment by using backups

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL

    .PARAMETER Organisation

    .PARAMETER Version

    .PARAMETER RestorePath

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

function checkResults($result) {
    if ($result.errors) {
        switch ($result.errors.message) {
            {$_ -match '409'} { Write-Warning "An entry already exists" }
            {$_ -match '400'} { Write-Warning "Invalid" }
            default { Write-Warning "Failed: $($result.errors.message)" }
        }
    }
}

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

# Test Paths
if (!(Test-Path -Path $generalPath -PathType Container)) { throw "'$generalPath' could not be found. Please investigate" }
if (!(Test-Path -Path $vocabPath, $vocabKeysPath -PathType Container)) {
    throw "There as an issue finding '$vocabPath' or sub-folders. Please investigate"
}
if (!(Test-Path -Path $dataSourceSetsPath, $dataSourcesPath, $dataSetsPath -PathType Container)) {
    throw "There as an issue finding '$dataPath' or sub-folders. Please investigate"
}

# Settings
Write-Host "INFO: Importing Admin Settings" -ForegroundColor 'Green'
$adminSetting = Get-Content -Path (Join-Path -Path $generalPath -ChildPath 'AdminSetting.json') | ConvertFrom-Json -Depth 20

$settings = ($adminSetting.data.administration.configurationSettings).psobject.properties.name

foreach ($setting in $settings) {
    # We apparently export API keys which need to be re-imported.
    # Need to find out where these are grabbed from and we can then store/retrieve from KV

    $key = $setting
    $value = $adminSetting.data.administration.configurationSettings.$key
    Write-Host "Processing Admin Setting: $key" -ForegroundColor Cyan
    $adminSettingResult = Set-CluedInAdminSettings -AdminSettingName $key -AdminSettingValue $value
    checkResults($adminSettingResult)
}

# Vocabulary
Write-Host "INFO: Importing Vocabularies" -ForegroundColor 'Green'
$vocabularies = Get-ChildItem -Path $vocabPath -Filter "*.json"
foreach ($vocabulary in $vocabularies) {
    $vocabJson = Get-Content -Path $vocabulary.FullName | ConvertFrom-Json -Depth 20
    $vocabObject = $vocabJson.data.management.vocabulary

    Write-Host "Processing Vocab: $($vocabObject.vocabularyName) ($($vocabObject.vocabularyId))" -ForegroundColor Cyan
    Write-Debug "$($vocabObject | Out-String)"

    # Check if entity Type exists and create if not found
    $entityTypeResult = Get-CluedInEntityType -Search $($vocabObject.entityTypeConfiguration.displayName)
    if ($entityTypeResult.data.management.entityTypeConfigurations.total -ne 1) {
        New-CluedInEntityType -Object $vocabObject.entityTypeConfiguration
    }

    $vocabResult = New-CluedInVocabulary -Object $vocabObject
    checkResults($vocabResult)
}

Write-Host "INFO: Importing Vocabulary Keys" -ForegroundColor 'Green'
$vocabKeys = Get-ChildItem -Path $vocabKeysPath -Filter "*.json"
foreach ($vocabKey in $vocabKeys) {
    $vocabKeyJson = Get-Content -Path $vocabKey.FullName | ConvertFrom-Json -Depth 20
    $vocabKeyObject = $vocabKeyJson.data.management.vocabularyKeysFromVocabularyId.data

    foreach ($key in $vocabKeyObject) {
        Write-Host "Processing Vocab Key: $($key.displayName) ($($key.vocabularyKeyId))" -ForegroundColor Cyan
        Write-Debug "$($key | Out-String)"

        $vocabulary = Get-CluedInVocabulary -Search $key.vocabulary.vocabularyName

        $params = @{
            Object = $key
            VocabId = $vocabulary.data.management.vocabularies.data.vocabularyId
        }
        $vocabKeyResult = New-CluedInVocabularyKey @params
        checkResults($vocabKeyResult)
    }
}

# Data Sources
Write-Host "INFO: Importing Data Source Sets" -ForegroundColor 'Green'

$dataSourceSets = Get-Content -Path (Join-Path -Path $dataSourceSetsPath -ChildPath 'DataSourceSet.json') | ConvertFrom-Json -Depth 20
foreach ($dataSourceSet in $dataSourceSets.data.inbound.dataSourceSets.data) {
    Write-Host "Processing Data Source Set: $($dataSourceSet.name) ($($dataSourceSet.id))" -ForegroundColor Cyan
    Write-Debug "$($dataSourceSet | Out-String)"

    $exists = (Get-CluedInDataSourceSet -Search $($dataSourceSet.name)).data.inbound.dataSourceSets.data

    if (!$exists) {
        $dataSourceSetResult = New-CluedInDataSourceSet -Object $dataSourceSet
        checkResults($dataSourceSetResult)
    }
    else { Write-Warning "An entry already exists" }
}

Write-Host "INFO: Importing Data Sources" -ForegroundColor 'Green'
$dataSources = Get-ChildItem -Path $dataSourcesPath -Filter "*.json"

foreach ($dataSource in $dataSources) {
    $dataSourceJson = Get-Content -Path $dataSource.FullName | ConvertFrom-Json -Depth 20
    $dataSourceObject = $dataSourceJson.data.inbound.dataSource
    $dataSourceSetName = $dataSourceObject.dataSourceSet.name

    $dataSourceSet = Get-CluedInDataSourceSet -Search $dataSourceSetName
    $dataSourceSetMatch = $dataSourceSet.data.inbound.dataSourceSets.data |
        Where-Object {$_.name -match "^$dataSourceSetName$"}
    if (!$dataSourceSetMatch) { Write-Warning "'$dataSourceSetName' was not found as a Data Source"; continue }
    $dataSourceObject.dataSourceSet.id = $dataSourceSetMatch.id

    Write-Host "Processing Data Source: $($dataSourceObject.name) ($($dataSourceObject.id))" -ForegroundColor 'Cyan'
    $exists = (Get-CluedInDataSource -Search $dataSourceObject.name).data.inbound.dataSource
    if (!$exists) {
        $dataSourceResult = New-CluedInDataSource -Object $dataSourceObject
        checkResults($dataSourceResult)
    }
    else { Write-Warning "An entry already exists" }
}

Write-Host "INFO: Importing Data Sets" -ForegroundColor 'Green'
$dataSets = Get-ChildItem -Path $dataSetsPath -Filter "*-DataSet.json"
foreach ($dataSet in $dataSets) {
    $dataSetJson = Get-Content -Path $dataSet.FullName | ConvertFrom-Json -Depth 20
    $dataSetObject = $dataSetJson.data.inbound.dataSet
    Write-Host "Processing Data Set: $($dataSetObject.name) ($($dataSetObject.id))" -ForegroundColor 'Cyan'

    $dataSource = Get-CluedInDataSource -Search $dataSetObject.dataSource.name
    if (!$dataSource) { Write-Warning "Data Source '$($dataSetObject.dataSource.name)' not found"; continue}
    $dataSetObject.dataSource.id = $dataSource.data.inbound.dataSource.id

    $exists = ($dataSetObject.name -in $dataSource.data.inbound.dataSource.dataSets.name)
    if (!$exists) {
        $dataSetResult = New-CluedInDataSet -Object $dataSetObject
        checkResults($dataSetResult)

        if ($dataSetObject.dataSource.type -eq 'endpoint') {
            $dataSetId = $dataSetResult.data.inbound.createDataSets.id
            $endpoint = '{0}/upload/api/endpoint/{1}' -f ${env:CLUEDIN_ENDPOINT}, $dataSetId
            Write-Host "New Endpoint created: $endPoint"

            # If the dataSet already exists, we need to assume the annotations were also restored.
            # So we only run this in the !exists block
            Write-Verbose "Importing Annotations"
            $annotationPath = Join-Path -Path $dataSetsPath -ChildPath ('{0}-Annotation.json' -f $dataSetObject.id)
            Try {
                $annotationJson = Get-Content -Path $annotationPath | ConvertFrom-Json -Depth 20
                $annotationObject = $annotationJson.data.preparation.annotation
                $annotationObject | Add-Member -Name dataSetId -Value $dataSetId -MemberType NoteProperty
                $annotationObject | Add-Member -Name type -Value 'endpoint' -MemberType NoteProperty

                $vocabName = $annotationObject.vocabulary.vocabularyName
                $vocabSearchResult = Get-CluedInVocabulary -Search $vocabName -IncludeCore
                $vocabObject = $vocabSearchResult.data.management.vocabularies
                if (!$vocabObject.total -eq 1) {
                    Write-Error "There was an issue getting vocab '${vocabName}'"
                    Write-Debug $($vocabObject | Out-String)
                    continue
                }
                $annotationObject.vocabulary.vocabularyId = $vocabObject.data.vocabularyId

                $annotationResult = New-CluedInAnnotation -Object $annotationObject
                checkResults($annotationResult)
            }
            catch {
                Write-Verbose "Annotation file '$annotationPath' not found or error occured during run"
                Write-Debug $_
                continue
            }
        }
    }
    else { Write-Warning "An entry already exists" }
}
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

function checkErrors($result) {
    if ($result.errors) { 
        switch ($result.errors.message) {
            {$_ -match '409'} { Write-Warning "An existing entry already exists" }
            {$_ -match '400'} { Write-Warning "Invalid" }
            default { Write-Warning "Failed: $($result.errors.message)" }
        }         
    }
}

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO: Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation -Version $Version

Write-Host "INFO: Starting import"

Write-Host "INFO: Importing Admin Settings"
$generalPath = Join-Path -Path $RestorePath -ChildPath 'General'
if (!(Test-Path -Path $generalPath -PathType Container)) { throw "'$generalPath' could not be found. Please investigate" }
$adminSetting = Get-Content -Path (Join-Path -Path $generalPath -ChildPath 'AdminSetting.json') | ConvertFrom-Json -Depth 20

$settings = ($adminSetting.data.administration.configurationSettings).psobject.properties.name

foreach ($setting in $settings) {
    # We apparently export API keys which need to be re-imported.
    # Need to find out where these are grabbed from and we can then store/retrieve from KV

    $key = $setting
    $value = $adminSetting.data.administration.configurationSettings.$key
    Write-Host "INFO: Processing Admin Setting '$key'"
    $adminSettingResult = Set-CluedInAdminSettings -AdminSettingName $key -AdminSettingValue $value
    checkErrors($adminSettingResult)
}

# Vocabulary
Write-Host "INFO: Importing Vocabularies"
$vocabPath = Join-Path -Path $RestorePath -ChildPath 'Vocab'
$vocabKeysPath = Join-Path -Path $vocabPath -ChildPath 'Keys'
if (!(Test-Path -Path $vocabKeysPath -PathType Container)) { 
    throw "There as an issue finding '$vocabPath' or sub-folders. Please investigate" 
}

$vocabularies = Get-Content -Path (Join-Path -Path $vocabPath -ChildPath 'Vocabularies.json') | ConvertFrom-Json -Depth 20
Write-Host "INFO: A total of $($vocabularies.data.management.vocabularies.total) vocabularies will be imported"

foreach ($vocab in $vocabularies.data.management.vocabularies.data) {
    Write-Host "Processing Vocab: $($vocab.vocabularyName) ($($vocab.vocabularyId))"
    Write-Debug "$($vocab | Out-String)"

    $vocabResult = New-CluedInVocabulary -Object $vocab
    checkErrors($vocabResult)
}

Write-Host "INFO: Importing Vocabulary Keys"
$vocabKeys = Get-ChildItem -Path $vocabKeysPath -Filter "*.json"
foreach ($vocabKey in $vocabKeys) {
    $vocabKeyJson = Get-Content -Path $vocabKey.FullName | ConvertFrom-Json -Depth 20
    $vocabKeyObject = $vocabKeyJson.data.management.vocabularyKeysFromVocabularyId.data

    foreach ($key in $vocabKeyObject) {
        Write-Host "Processing Vocab Key: $($key.displayName) ($($key.vocabularyKeyId))"
        Write-Debug "$($key | Out-String)"

        $vocabulary = Get-CluedInVocabulary -Search $key.vocabulary.vocabularyName

        $params = @{
            Object = $key
            VocabId = $vocabulary.data.management.vocabularies.data.vocabularyId
        }
        $vocabKeyResult = New-CluedInVocabularyKey @params
        checkErrors($vocabKeyResult)
    }    
}

# Data Sources
Write-Host "INFO: Importing Data Source Sets"
$dataPath = Join-Path -Path $RestorePath -ChildPath 'Data'
$dataSourceSetsPath = Join-Path -Path $dataPath -ChildPath 'SourceSets'
$dataSourcesPath = Join-Path -Path $dataPath -ChildPath 'Sources'
$dataSetsPath = Join-Path -Path $dataPath -ChildPath 'Sets'
if (!(Test-Path -Path $dataSourceSetsPath, $dataSourcesPath, $dataSetsPath -PathType Container)) {
    throw "There as an issue finding '$dataPath' or sub-folders. Please investigate" 
}

$dataSourceSets = Get-Content -Path (Join-Path -Path $dataSourceSetsPath -ChildPath 'DataSourceSet.json') | ConvertFrom-Json -Depth 20
Write-Host "INFO: A total of $($dataSourceSets.data.inbound.datasourcesets.total) data source sets will be imported"

foreach ($dataSourceSet in $dataSourceSets.data.inbound.dataSourceSets.data) {
    Write-Host "Processing Data Source Set: $($dataSourceSet.name) ($($dataSourceSet.id))"
    Write-Debug "$($dataSourceSet | Out-String)"

    $dataSourceSetResult = New-CluedInDataSourceSet -Object $dataSourceSet
    checkErrors($dataSourceSetResult)
}

#Write-Host "INFO: Importing Data Sources"
#$dataSources = Get-ChildItem -Path $dataSourcesPath -Filter "*.json"
#
#foreach ($dataSource in $dataSources) {
#    $dataSourceJson = Get-Content -Path $dataSource.FullName | ConvertFrom-Json -Depth 20
#    $dataSourceObject = $dataSourceJson.data.inbound.dataSource
#    $dataSourceSetName = $dataSourceObject.dataSourceSet.name
#
#    $dataSourceSet = Get-CluedInDataSourceSet -Search $dataSourceSetName
#    $dataSourceSetExact = $dataSourceSet.data.inbound.dataSourceSets.data | 
#        Where-Object {$_.name -match "^$dataSourceSetName$"}
#    $dataSourceObject.dataSourceSet.id = $dataSourceSetExact.id
#
#    Write-Host "Processing Data Source: $($dataSourceObject.name) ($($dataSourceObject.id))"
#    $dataSourceResult = New-CluedInDataSource -Object $dataSourceObject
#    checkErrors($dataSourceResult)
#}
#
#Write-Host "INFO: Importing Data Sets"
#$dataSets = Get-ChildItem -Path $dataSetsPath -Filter "*-DataSet.json"
#foreach ($dataSet in $dataSets) {
#    $dataSetJson = Get-Content -Path $dataSet.FullName | ConvertFrom-Json -Depth 20
#    $dataSetObject = $dataSetJson.data.inbound.dataSet
#    $dataSource = Get-CluedInDataSource -Search $dataSetObject.dataSource.name
#    $dataSetObject.dataSource.id = $dataSource.data.inbound.dataSource.id
#
#    $dataSetResult = New-CluedInDataSet -Object $dataSetObject
#    checkErrors($dataSetResult)
#
#    if ($dataSetObject.dataSource.type -eq 'endpoint') {
#        $guid = $dataSetResult.data.inbound.createDataSets.id
#        $endpoint = '{0}/upload/api/endpoint/{1}' -f ${env:CLUEDIN_ENDPOINT}, $guid
#        Write-Host "New Endpoint created: $endPoint"
#    }
#}
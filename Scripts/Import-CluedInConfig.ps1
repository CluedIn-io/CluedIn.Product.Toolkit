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
    if ($result.errors) { Write-Warning "Failed: $($result.errors.message)" }
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

    Set-CluedInAdminSettings -AdminSettingName $key -AdminSettingValue $value
}

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
    if ($vocabResult.errors) { Write-Warning "Failed: $($vocabResult.errors.message)" }

    Write-Verbose "Fetching Keys for vocabId: $($vocab.vocabularyId)" # This is to find the matching export. Not the new vocab
    $vocabKeys = Get-Content -Path (Join-Path -Path $vocabKeysPath -ChildPath "$($vocab.vocabularyId).json") | ConvertFrom-Json -Depth 20
    foreach ($vocabKey in $vocabKeys.data.management.vocabularyKeysFromVocabularyId.data) {
        Write-Host "Processing Vocab Key: $($vocabKey.displayName) ($($vocabKey.vocabularyKeyId))"
        Write-Debug "$($vocabKey | Out-String)"

        $params = @{
            Object = $vocabKey
            VocabId = $vocabResult.data.management.createVocabulary.vocabularyId
        }
        $vocabKeyResult = New-CluedInVocabularyKey @params
        checkErrors($vocabKeyResult)
    }
}

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

Write-Host "INFO: Importing Data Sources"
$dataSources = Get-ChildItem -Path $dataSourcesPath -Filter "*.json"

foreach ($dataSource in $dataSources) {
    $dataSourceJson = Get-Content -Path $dataSource.FullName | ConvertFrom-Json -Depth 20
    $dataSourceObject = $dataSourceJson.data.inbound.dataSource
    $dataSourceSetName = $dataSourceObject.dataSourceSet.name

    $dataSourceSet = Get-CluedInDataSourceSet -Search $dataSourceSetName
    $dataSourceSetExact = $dataSourceSet.data.inbound.dataSourceSets.data | 
        Where-Object {$_.name -match "^$dataSourceSetName$"}
    $dataSourceObject.dataSourceSet.id = $dataSourceSetExact.id

    Write-Host "Processing Data Source: $($dataSourceObject.name) ($($dataSourceObject.id))"
    $dataSourceResult = New-CluedInDataSource -Object $dataSourceObject
    checkErrors($dataSourceResult)
}

Write-Host "INFO: Importing Data Sets"
$dataSets = Get-ChildItem -Path $dataSetsPath -Filter "*-DataSet.json"
foreach ($dataSet in $dataSets) {
    $dataSetJson = Get-Content -Path $dataSet.FullName | ConvertFrom-Json -Depth 20
    $dataSetObject = $dataSetJson.data.inbound.dataSet


}
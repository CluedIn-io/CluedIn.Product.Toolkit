<#
    .SYNOPSIS
    Imports configuration to the connected environment by using backups

    .DESCRIPTION
    Imports configuration to the connected environment by using backups

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
    [Parameter(Mandatory)][string]$RestorePath = 'C:\.dev\EXPORTTEST'
)

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO: Connecting to 'https://$Organisation.$BaseURL'"
Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organisation -Version $Version

Write-Host "INFO: Starting import"

Write-Host "INFO: Importing Admin Settings"
$generalPath = Join-Path -Path $RestorePath -ChildPath 'General'
if (!(Test-Path -Path $generalPath -PathType Container)) { throw "'$generalPath' could not be found. Please investigate" }
$adminSetting = Get-Content -Path (Join-Path -Path $generalPath -ChildPath 'AdminSetting.json') | ConvertFrom-Json -Depth 99

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
if (!(Test-Path -Path $vocabPath -PathType Container)) { throw "There as an issue finding '$vocabPath'. Please ensuer it exists" }
$vocabularies = Get-Content -Path (Join-Path -Path $vocabPath -ChildPath 'Vocabularies.json') | ConvertFrom-Json
Write-Host "INFO: A total of $($vocabularies.data.management.vocabularies.total) vocabularies will be imported"

foreach ($vocab in $vocabularies.data.management.vocabularies.data) {
    $vocabName = $vocab.vocabularyName
    Write-Debug "vocabName: $vocabName"
    $vocabId = $vocab.vocabularyId
    Write-Debug "vocabId: $vocabId"
    $vocabGrouping = $vocab.grouping
    Write-Debug "vocabGrouping: $vocabGrouping"
    $vocabPrefix = $vocab.keyPrefix
    Write-Debug "vocabPrefix: $vocabPrefix"

    Write-Host "Processing Vocab: $vocabName ($vocabId)"
    $result = New-CluedInVocabulary -DisplayName $vocabName -EntityCode $vocabGrouping -Provider "" -Prefix $vocabPrefix
    Write-Host ($result | Out-String)

    Write-Verbose "Fetching Keys for vocabId: $vocabId"
    $vocabKeys = Get-Content -Path (Join-Path -Path $vocabKeysPath -ChildPath "$vocabId.json") | ConvertFrom-Json -Depth 99
    foreach ($vocabKey in $vocabKeys.data.management.vocabularyKeysFromVocabularyId.data) {
        Write-Host "Processing Vocab Key: $($vocabKey.displayName) ($($vocabKey.vocabularyKeyId))"
        $params = @{
            DisplayName = $vocabKey.displayName
            GroupName = $vocabKey.groupName
            DataType = $vocabKey.dataType
            Description = $vocabKey.description
            Prefix = $vocabKey.name
            VocabId = $vocabId
        }
        New-CluedInVocabularyKey @params
    }
}

#Write-Host "INFO: Importing Vocabulary Keys"
#
#Write-Host "INFO: Importing Data Source Sets"
#
#Write-Host "INFO: Importing Data Sources"
#
#Write-Host "INFO: Importing Data Sets"
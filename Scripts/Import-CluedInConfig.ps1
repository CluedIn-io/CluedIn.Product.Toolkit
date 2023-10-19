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
if (!(Test-Path -Path $vocabPath -PathType Container)) { throw "There as an issue finding '$vocabPath'. Please ensuer it exists" }
$vocabularies = Get-Content -Path (Join-Path -Path $vocabPath -ChildPath 'Vocabularies.json') | ConvertFrom-Json -Depth 20
Write-Host "INFO: A total of $($vocabularies.data.management.vocabularies.total) vocabularies will be imported"

foreach ($vocab in $vocabularies.data.management.vocabularies.data) {
    Write-Debug "$($vocab | Out-String)"

    Write-Host "Processing Vocab: $($vocab.vocabularyName) ($($vocab.vocabularyId))"
    $vocabResult = New-CluedInVocabulary -Object $vocab
    if ($vocabResult.errors) { Write-Warning "Failed: $($vocabResult.errors.message)" }

    Write-Verbose "Fetching Keys for vocabId: $($vocab.vocabularyId)" # This is to find the matching export. Not the new vocab
    $vocabKeys = Get-Content -Path (Join-Path -Path $vocabKeysPath -ChildPath "$($vocab.vocabularyId).json") | ConvertFrom-Json -Depth 20
    foreach ($vocabKey in $vocabKeys.data.management.vocabularyKeysFromVocabularyId.data) {
        Write-Host "Processing Vocab Key: $($vocabKey.displayName) ($($vocabKey.vocabularyKeyId))"
        $params = @{
            Object = $vocabKey
            VocabId = $vocabResult.data.management.createVocabulary.vocabularyId
        }
        $vocabKeyResult = New-CluedInVocabularyKey @params
        if ($vocabKeyResult.errors) { Write-Warning "Failed: $($vocabResult.errors.message)" }
    }
}

Write-Host "INFO: Importing Data Source Sets"

#
#Write-Host "INFO: Importing Data Sources"
#
#Write-Host "INFO: Importing Data Sets"
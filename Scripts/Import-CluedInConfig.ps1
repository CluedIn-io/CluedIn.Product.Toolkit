<#
    .SYNOPSIS
    Imports configuration to the connected environment by using backups

    .DESCRIPTION
    Imports configuration to the connected environment by using backups

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL
    This is the base url of your clued in instance. If you access CluedIn by https://cluedin.domain.com, the BaseURL is 'domain.com'

    .PARAMETER Organization
    This is the section before your base URL. If you access CluedIn by https://cluedin.domain.com, the Organization is 'cluedin'

    .PARAMETER RestorePath
    This is the location of the export files ran by Export-CluedInConfig

    .PARAMETER IncludeSupportFiles
    Exports a transcript along with the produced JSON files for CluedIn support to use to diagnose any issues relating to migration.

    .EXAMPLE
    PS> ./Import-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organization 'dev' -RestorePath /path/to/backups
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][Alias('Organisation')][string]$Organization,
    [Parameter(Mandatory)][string]$RestorePath,
    [switch]$UseHTTP,
    [switch]$IncludeSupportFiles
)

function Check-ImportResult($Result,$Type)
{
    if ($Result.errors) {
        switch ($Result.errors.message) {
            {$_ -match '409'} { 
                if($Type -eq 'vocab') {
                    Write-Host "Skipping vocab already exists or was unchanged" -ForegroundColor 'Cyan'
                } else {
                    Write-Warning "An entry already exists" 
                }
            }
            default 
            { 
                Write-Warning "Failed: $($Result.errors.message)" 
            }
        }
    }
}

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

# Variables
Write-Verbose "Setting Script Variables"
$dataCatalogPath = Join-Path -Path $RestorePath -ChildPath 'DataCatalog'
$vocabPath = Join-Path -Path $dataCatalogPath -ChildPath 'Vocab'
$vocabKeysPath = Join-Path -Path $dataCatalogPath -ChildPath 'Keys'
$generalPath = Join-Path -Path $RestorePath -ChildPath 'General'
$rulesPath = Join-Path -Path $RestorePath -ChildPath 'Rules'
$exportTargetsPath = Join-Path -Path $RestorePath -ChildPath 'ExportTargets'
$streamsPath = Join-Path -Path $RestorePath -ChildPath 'Streams'
$glossariesPath = Join-Path -Path $RestorePath -ChildPath 'Glossaries'
$cleanProjectsPath = Join-Path -Path $RestorePath -ChildPath 'CleanProjects'

$allUsers = (Get-CluedInUsers).data.administration.users # Caching for use down below

# Test Paths
if (!(Test-Path -Path $generalPath -PathType Container)) { throw "'$generalPath' could not be found. Please investigate" }
if (!(Test-Path -Path $vocabPath, $vocabKeysPath -PathType Container)) {
    throw "There as an issue finding '$vocabPath' or sub-folders. Please investigate"
}

# Settings
$adminSettingsPath = Join-Path -Path $generalPath -ChildPath 'AdminSetting.json'
if (Test-Path -Path $adminSettingsPath -PathType Leaf) {
    Write-Host "INFO: Importing Admin Settings" -ForegroundColor 'Green'
    $restoreAdminSetting = Get-Content -Path $adminSettingsPath | ConvertFrom-Json -Depth 20

    $settings = ($restoreAdminSetting.data.administration.configurationSettings).psobject.properties.name
    $currentSettings = (Get-CluedInAdminSetting).data.administration.configurationSettings

    $settingsToUpdate = @{}

    foreach ($setting in $settings) {
        $key = $setting

        if ($key -notin $currentSettings.psobject.properties.name) {
            Write-Verbose "Skipping '$key' as it's not a current setting"
            continue
        }

        $newValue = $restoreAdminSetting.data.administration.configurationSettings.$key
        $currentValue = $currentSettings.$key

        # Determine if the value has changed
        $hasChanged = $newValue -ne $currentValue

        $settingsToUpdate[$key] = $newValue

        if ($hasChanged) {
            Write-Host "Processing Admin Setting '$key'. Was: $currentValue, Now: $newValue" -ForegroundColor 'Cyan'
        }
    }

    if ($settingsToUpdate.Count -gt 0) {
        Write-Host "INFO: Performing bulk update of admin settings..." -ForegroundColor 'Cyan'
        $bulkResult = Set-CluedInAdminSettingsBulk -SettingsToApply $settingsToUpdate
        Check-ImportResult($bulkResult)
    }
}

# Glossaries
Write-Host "INFO: Importing Glossaries" -ForegroundColor 'Green'
$glossaries = Get-ChildItem -Path $glossariesPath -Directory -ErrorAction 'SilentlyContinue'

$currentGlossaries = Get-CluedInGlossary
$currentGlossariesObject = $currentGlossaries.data.management.glossaryCategories

$currentTerms = Get-CluedInGlossaryTerms
$currentTermsObject = $currentTerms.data.management.glossaryTerms.data

$lookupGlossaryTerms = @()

foreach ($glossary in $glossaries) {
    $glossaryId = $null
    $glossaryPath = $glossary.FullName
    $glossaryFile = Get-ChildItem -Path $glossaryPath -Filter "*Glossary.json" -Recurse
    if ($glossaryFile.count -eq 0) { Write-Verbose "No glossaries, continuing"; continue }
    if ($glossaryFile.count -gt 1) { Write-Warning "Too many Glossary files found. Skipping"; continue }

    $termsFile = Get-ChildItem -Path $glossaryPath -Filter "*Term.json" -Recurse

    $glossaryJson = Get-Content -Path $glossaryFile.FullName | ConvertFrom-Json -Depth 20
    $glossaryObject = $glossaryJson.data.management.glossaryCategory

    Write-Host "Processing Glossary: $($glossaryObject.name)" -ForegroundColor 'Green'
    if ($glossaryObject.name -notin $currentGlossariesObject.name) {
        Write-Host "Creating Glossary '$($glossaryObject.name)'" -ForegroundColor 'Cyan'
        $glossaryResult = New-CluedInGlossary -Name $glossaryObject.name
        
        Check-ImportResult -Result $glossaryResult

        $glossaryId = $glossaryResult.data.management.createGlossaryCategory.id
    }

    $glossaryId = $glossaryId ?? ($currentGlossariesObject | Where-Object { $_.name -eq $glossaryObject.name }).id

    Write-Verbose "Processing Terms"
    foreach ($term in $termsFile) {
        $termId = $null
        $termJson = Get-Content -Path $term.FullName | ConvertFrom-Json -Depth 20
        $termObject = $termJson.data.management.glossaryTerm
        $termRuleSet = $termObject.ruleSet

        if($null -eq $termRuleSet -Or $termRuleSet.rules.count -eq 0){
            Write-Warning "Skipping Term '$($termObject.name)' as it does not have a valid filter"
            continue
        }

        Write-Host "Processing Term: $($termObject.name)" -ForegroundColor 'Cyan'
        if ($termObject.name -notin $currentTermsObject.name) {
            Write-Host "Creating Term '$($termObject.name)'" -ForegroundColor 'DarkCyan'

            $termResult = New-CluedInGlossaryTerm -Name $termObject.name -GlossaryId $glossaryId -RuleSet $termRuleSet

            Check-ImportResult -Result $termResult

            $termId = $termResult.data.management.createGlossaryTerm.id
        }

        $termId = $termId ?? ($currentTermsObject | Where-Object { $_.name -eq $termObject.name }).id

        $lookupGlossaryTerms += [PSCustomObject]@{
            OriginalGlossaryTermId = $termObject.id
            GlossaryTermId = $termId
        }

        Write-Host "Updating Term Configuration" -ForegroundColor 'DarkCyan'
        $setTermResult = Set-CluedInGlossaryTerm -Id $termId -Object $termObject -GlossaryId $glossaryId
        Check-ImportResult -Result $setTermResult
    }
}

# Vocabulary
Write-Host "INFO: Importing Vocabularies" -ForegroundColor 'Green'
$restoreVocabularies = Get-ChildItem -Path $vocabPath -Filter "*.json"
$lookupVocabularies = @()

foreach ($vocabulary in $restoreVocabularies) {
    $vocabJson = Get-Content -Path $vocabulary.FullName | ConvertFrom-Json -Depth 20
    $vocabObject = $vocabJson.data.management.vocabulary
    $originalVocabularyId = $vocabObject.vocabularyId

    Write-Host "Processing Vocab: $($vocabObject.vocabularyName) ($($vocabObject.vocabularyId))" -ForegroundColor 'Cyan'
    
    $entityTypeResult = Get-CluedInEntityType -Search $($vocabObject.entityTypeConfiguration.displayName)
    if ($entityTypeResult.data.management.entityTypeConfigurations.total -lt 1) {
        Write-Host "Creating entity type: $($entityTypeResult.data.management.entityTypeConfigurations.total)" 
        $entityResult = New-CluedInEntityType -Object $vocabObject.entityTypeConfiguration
        Check-ImportResult -Result $entityResult
    }

    $exists = (Get-CluedInVocabulary -Search $vocabObject.vocabularyName -IncludeCore -HardMatch).data.management.vocabularies.data
    if (!$exists) {
        $vocabCreateResult = New-CluedInVocabulary -Object $vocabObject
        Check-ImportResult -Result $vocabCreateResult
        $createdVocabulary = (Get-CluedInVocabulary -Search $vocabObject.vocabularyName -HardMatch).data.management.vocabularies.data
        
        $lookupVocabularies += [PSCustomObject]@{
            OriginalVocabularyId = $originalVocabularyId
            VocabularyId = $createdVocabulary.vocabularyId
        }
    }
    else {
        $vocabularyId = $null
        if ($exists.count -ne 1) { 
            
            $found = $false
            foreach ($v in $exists)
            {
                if($v.keyPrefix -eq $vocabObject.keyPrefix) {
                    $vocabularyId = $v.vocabularyId
                    $found = $true
                    break
                }
            }
                
            if($found -eq $false) {
                Write-Warning "Can not find exact match for the vocabulary"; 
                continue 
            }
        } else {
            $vocabularyId = $exists.vocabularyId
        }
        $vocabularyId = $null
        if ($exists.count -ne 1) { 
            
            $found = $false
            foreach ($v in $exists)
            {
                if($v.keyPrefix -eq $vocabObject.keyPrefix) {
                    $vocabularyId = $v.vocabularyId
                    $found = $true
                    break
                }
            }
                
            if($found -eq $false) {
                Write-Warning "Can not find exact match for the vocabulary"; 
                continue 
            }
        } else {
            $vocabularyId = $exists.vocabularyId
        }

        # We have to get again because the `exists` section doesn't pull the configuration. Just metadata.
        $currentVocab = (Get-CluedInVocabularyById -Id $vocabularyId).data.management.vocabulary
        $currentVocab = (Get-CluedInVocabularyById -Id $vocabularyId).data.management.vocabulary
        $vocabObject.vocabularyId = $currentVocab.vocabularyId # These cannot be updated once set
        $vocabObject.vocabularyName = $currentVocab.vocabularyName # These cannot be updated once set
        $vocabObject.keyPrefix = $currentVocab.keyPrefix # These cannot be updated once set

        Write-Verbose "'$($vocabObject.vocabularyName)' already exists, overwriting existing configuration"
        Write-Verbose "Restored Config`n$($vocabObject | Out-String)"
        Write-Verbose "Current Config`n$($currentVocab | Out-String)"
        $vocabUpdateResult = Set-CluedInVocabulary -Object $vocabObject
        Check-ImportResult -Result $vocabUpdateResult -Type 'vocab'

        $lookupVocabularies += [PSCustomObject]@{
            OriginalVocabularyId = $originalVocabularyId
            VocabularyId = $currentVocab.vocabularyId
        }
    }
}

Write-Host "INFO: Importing Vocabulary Keys" -ForegroundColor 'Green'
$vocabKeys = Get-ChildItem -Path $vocabKeysPath -Filter "*.json"
foreach ($vocabKey in $vocabKeys) {
    $vocabKeyJson = Get-Content -Path $vocabKey.FullName | ConvertFrom-Json -Depth 20
    $vocabKeyObject = $vocabKeyJson.data.management.vocabularyKeysFromVocabularyId.data

    if($vocabKeyObject.count -eq 0){
        # There are no vocabulary keys to import from that file
        continue
    }

    $vocabName = ''
    $lookupVocabularyId = $null

    $everyKeyIsACompositeKey = $true

    # Find first key that is not a composite key to identify the new vocabulary id to assign the keys to
    foreach($vk in $vocabKeyObject)
    {
        if($null -eq $vk.compositeVocabularyId)
        {
            $vocabName = $vk.vocabulary.vocabularyName
            $lookupVocabularyId = $vk.vocabularyId
            $everyKeyIsACompositeKey = $false
            break
        }
    }

    if($everyKeyIsACompositeKey -eq $true){
        Write-Warning "All vocabulary keys are composite keys so skipping the file '$($vocabKey.FullName)'"
        continue
    }

    $vocabularyId = ($lookupVocabularies | Where-Object { $_.OriginalVocabularyId -eq $lookupVocabularyId }).VocabularyId
    if([string]::IsNullOrWhiteSpace($vocabularyId))
    {
        Write-Error "Can not find matching vocabulary for '$vocabName'"
        continue
    }

    foreach ($key in $vocabKeyObject) {
        if ($key.isObsolete) { 
            Write-Verbose "Not importing: '$($key.key)' as it's obsolete"; 
            continue 
        }

        Write-Host "Processing Vocab Key: $($key.displayName) ($($key.vocabularyKeyId))" -ForegroundColor 'Cyan'

        $currentVocabularyKeyObjectResult = Get-CluedInVocabularyKey -Search $key.key
        $currentVocabularyKeyObject = $currentVocabularyKeyObjectResult.data.management.vocabularyPerKey
        
        if ($key.mapsToOtherKeyId) {
            $mappedKeyId = Get-CluedInVocabularyKey -Search $key.mappedKey.key
            $key.mapsToOtherKeyId = $mappedKeyID ?
                $mappedKeyId.data.management.vocabularyPerKey.vocabularyKeyId :
                $null
        }

        if($null -ne $key.compositeVocabularyId) {
            Write-Host "Skipping composite Vocab Key: $($key.key)" -ForegroundColor 'DarkCyan'
            continue
        }

        if($key.dataType -eq "Text" -And $key.storage -ne "Keyword"){
            # As of 4.4.0 Anything with datatype text must be stored as a Keyword
            Write-Warning "Changing the storage type to 'Keyword' for '$($key.key)' as keys with a Text data type now have to be stored as 'Keywords"
            $key.storage = "Keyword"
        }

        if (!$currentVocabularyKeyObject.key) {
            Write-Host "Creating '$($key.key)' as it doesn't exist" -ForegroundColor 'DarkCyan'
            $keyVocabularyId = ($lookupVocabularies | Where-Object { $_.OriginalVocabularyId -eq $key.vocabularyId }).VocabularyId
            Write-Host "Creating vocab id:: $($key.vocabularyId) new:::'$($keyVocabularyId)'" -ForegroundColor 'DarkCyan'
            if([string]::IsNullOrWhiteSpace($keyVocabularyId))
            {
                Write-Warning "Can not find matching vocab '$vocabName' for key '$($key.key)'"
                continue
            }
            
            if($key.dataType -eq "Lookup"){
                Write-Host "Resolving Lookup Glossary Term"  -ForegroundColor 'DarkCyan'
                $glossaryTermId = ($lookupGlossaryTerms | Where-Object { $_.OriginalGlossaryTermId -eq $key.glossaryTermId }).GlossaryTermId
                if([string]::IsNullOrWhiteSpace($glossaryTermId))
                {
                    Write-Error "Can not find matching glossary term for the look field. Vocabulary: '$vocabName'; NewGlossaryTermId: '$glossaryTermId'; OriginalTermId: '$($key.glossaryTermId)'"
                    continue
                }
                Write-Host "Updating lookup glossary term id. Vocabulary: '$vocabName'; NewGlossaryTermId: '$glossaryTermId'; OriginalGlossaryTermId: '$($key.glossaryTermId)'"  -ForegroundColor 'DarkCyan'
                $key.glossaryTermId = $glossaryTermId
            }

            $params = @{
                Object = $key
                VocabId = $keyVocabularyId
            }
            $vocabKeyResult = New-CluedInVocabularyKey @params
            Check-ImportResult -Result $vocabKeyResult

            if ($?) {
                $key.vocabularyId = $vocabKeyResult.data.management.createVocabularyKey.vocabularyId
                $key.vocabularyKeyId = $vocabKeyResult.data.management.createVocabularyKey.vocabularyKeyId
            }
        }
        else {
            $key.vocabularyKeyId = $currentVocabularyKeyObject.vocabularyKeyId # These cannot be updated once set
            $key.vocabularyId = $currentVocabularyKeyObject.vocabularyId # These cannot be updated once set
            $key.name = $currentVocabularyKeyObject.name # These cannot be updated once set

            $keyVocabularyId = ($lookupVocabularies | Where-Object { $_.VocabularyId -eq $currentVocabularyKeyObject.vocabularyId }).VocabularyId
            if([string]::IsNullOrWhiteSpace($keyVocabularyId))
            {
                Write-Warning "Can not find matching vocab '$vocabName' for key '$($key.key)' - $($currentVocabularyKeyObject.vocabularyId)"
                #continue
            }

            Write-Verbose "'$($key.key)' exists, overwriting existing configuration"
            $vocabKeyUpdateResult = Set-CluedInVocabularyKey -Object $key
            Check-ImportResult -Result $vocabKeyUpdateResult
        }

        if ($key.mapsToOtherKeyId) {
            Write-Verbose "Processing Vocabulary Key Mapping"
            $keyLookup = Get-CluedInVocabularyKey -Search $key.mappedKey.key
            $keyLookupId = $keyLookup.data.management.vocabularyPerKey.vocabularyKeyId

            if ($keyLookupId) {
                Write-Host "Setting Vocab Key mapping '$($key.key)' to '$($key.mappedKey.key)'" -ForegroundColor 'DarkCyan'
                $mapResult = Set-CluedInVocabularyKeyMapping -Source $key.vocabularyKeyId -Destination $keyLookupId
                Check-ImportResult -Result $mapResult
            }
        }
    }
}

Import-DataSources -RestorePath $RestorePath

Import-DataSets -RestorePath $RestorePath

# Rules
Write-Host "INFO: Importing Rules" -ForegroundColor 'Green'
$rules = Get-ChildItem -Path $rulesPath -Filter "*.json" -Recurse
foreach ($rule in $rules) {
    $ruleJson = Get-Content -Path $rule.FullName | ConvertFrom-Json -Depth 20
    $ruleObject = $ruleJson.data.management.rule
    Write-Host "Processing Rule: $($ruleObject.name) ($($ruleObject.scope))" -ForegroundColor 'Cyan'
    $exists = Get-CluedInRules -Search $ruleObject.name -Scope $ruleObject.scope

    if (!$exists.data.management.rules.data) {
        Write-Verbose "Creating rule as it does not exist"
        $ruleResult = New-CluedInRule -Name $ruleObject.name -Scope $ruleObject.scope
        Check-ImportResult -Result $ruleResult
        $ruleObject.id = $ruleResult.data.management.createRule.id
    }
    else { 
        $ruleObject.id = $exists.data.management.rules.data.id 

        if($exists.data.management.rules.data.count -gt 1)
        {
            Write-Warning "Multiple matches for rule '$($ruleObject.name)'"
            foreach($item in $exists.data.management.rules.data)
            {
                if($item.name -eq $ruleObject.name)
                {
                    $ruleObject.id = $item.id 
                    continue
                }
            }
        } else {           
            $ruleObject.id = $exists.data.management.rules.data.id 
        }
    }

    Write-Verbose "Setting rule configuration"
    $setRuleResult = Set-CluedInRule -Object $ruleObject
    Check-ImportResult -Result $setRuleResult
}

# Export Targets
Write-Host "INFO: Importing Export Targets" -ForegroundColor 'Green'
$exportTargets = Get-ChildItem -Path $exportTargetsPath -Filter "*.json" -Recurse
$installedExportTargets = (Get-CluedInInstalledExportTargets).data.inbound.connectors

$cleanProperties = @(
    'connectinString', 'connectionString', 'password'
    'AccountKey', 'authorization'
)
# # # $cleanProperties = @(
# # #     'connectinString', 'password', 'host'
# # #     'AccountKey', 'AccountName', 'authorization'
# # # )

$lookupConnectors = @()

$currentExportTargets = (Get-CluedInExportTargets).data.inbound.connectorConfigurations.configurations
$targetExists = $targetObject.accountId -in $currentExportTargets.accountId

foreach ($target in $exportTargets) {
    $targetJson = Get-Content -Path $target.FullName | ConvertFrom-Json -Depth 20
    $targetObject = $targetJson.data.inbound.connectorConfiguration
    $targetProperties = ($targetObject.helperConfiguration | Get-Member -MemberType 'NoteProperty').Name
    $originalConnectorId = $targetObject.id

    Write-Host "Processing Export Target: $($targetObject.accountDisplay)" -ForegroundColor 'Cyan'
    if (!$targetObject.accountId) {
        $targetObject.accountId = '0'
        # Write-Warning "Account Id is null, cannot compare. Skipping."
        # Write-Host "You will need to manually add the '$($targetObject.name)' connector"
        # continue
    }

    $cleanProperties.ForEach({
        if ($_ -in $targetProperties) { $targetObject.helperConfiguration.$_ = $null }
    })

    # We should constantly get latest as we may create a new one in prior iteration.
    #$currentExportTargets = (Get-CluedInExportTargets).data.inbound.connectorConfigurations.configurations
    
    $hasTarget = $false
    $id = $null;

    if($null -ne $currentExportTargets)
    {
        foreach($exportTarget in $currentExportTargets) {
            $exportTargetDisplayName = $exportTarget.accountDisplay.Trim()
            $targetDisplayName = "$($targetObject.helperConfiguration.accountName) $($targetObject.helperConfiguration.fileSystemName) $($targetObject.helperConfiguration.directoryName)"

            if(($targetObject.accountId -eq $currentExportTargets.accountId) -and ($null -ne $targetObject.accountId) -and ('' -ne $targetObject.accountId) -and ('0' -ne $targetObject.accountId))
            {
                Write-Verbose "Found match on account id :: $($exportTarget.accountDisplay) == $($targetObject.accountDisplay)"
                $hasTarget = $true
                $id = $exportTarget.id
                break
            }
            elseif(($exportTarget.accountDisplay -eq $targetObject.accountDisplay) -and ($exportTarget.providerId -eq $targetObject.providerId))
            {
                Write-Verbose "Found match on display name :: $($exportTarget.accountDisplay) == $($targetObject.accountDisplay)"
                $hasTarget = $true
                $id = $exportTarget.id
                break
            }
            elseif(($exportTargetDisplayName -eq $targetDisplayName) -and ($exportTarget.providerId -eq $targetObject.providerId))
            {
                Write-Verbose "Found match on assumed display name :: $($exportTarget.accountDisplay) == $($targetObject.helperConfiguration.accountName) $($targetObject.helperConfiguration.fileSystemName) $($targetObject.helperConfiguration.directoryName)"
                $hasTarget = $true
                $id = $exportTarget.id
                break
            }
        }
    }

    if ($hasTarget -eq $false) {
        if ($targetObject.providerId -notin $installedExportTargets.id) {
            Write-Warning "Export Target '$($targetObject.connector.name)' could not be found. Skipping creation."
            Write-Warning "Please install connector and try again"
            continue
        }
        
        Write-Verbose "Creating Export Target $($targetObject.helperConfiguration)"
        # If the accountDisplay is null, we use id instead as the account display
        $accountDisplay = if ($targetObject.accountDisplay) { $targetObject.accountDisplay } else { $targetObject.id }
        $targetResult = New-CluedInExportTarget -ConnectorId $targetObject.providerId -Configuration $targetObject.helperConfiguration -AccountDisplay $accountDisplay

        $id = $targetResult.data.inbound.createConnection.id
        if (!$id) { Write-Warning "Unable to get Id of target. Importing on top of existing export targets can be flakey. Please manually investigate."; continue }
    }
    else {
        Write-Verbose "Updating Export target '$($targetDisplayName)' as it already exists"
        $targetResult = Set-CluedInExportTargetConfiguration -Id $id -AccountDisplay $targetObject.accountDisplay -Configuration $targetObject.helperConfiguration
    }

    Check-ImportResult -Result $targetResult

    Write-Verbose "Setting Permissions"
    $currentTarget = (Get-CluedInExportTarget -Id $id).data.inbound.connectorConfiguration
    $usersToAdd = Compare-Object -ReferenceObject $currentTarget.users.username -DifferenceObject $targetObject.users.username -PassThru |
        Where-Object { $_.SideIndicator -eq '=>' }

    $idsToSet = @()
    foreach ($user in $usersToAdd) {
        $idsToSet += ($allUsers | Where-Object { $_.account.UserName -eq $user }).id
    }

    if ($idsToSet) { Set-CluedInExportTargetPermissions -ConnectorId $id -UserId $idsToSet }

    $lookupConnectors += [PSCustomObject]@{
        OriginalConnectorId = $originalConnectorId
        ConnectorId = $id
    }
}

# Streams
Write-Host "INFO: Importing Streams" -ForegroundColor 'Green'
$streams = Get-ChildItem -Path $streamsPath -Filter "*.json" -Recurse
$existingStreams = (Get-CluedInStreams).data.consume.streams.data

foreach ($stream in $streams) {
    $streamJson = Get-Content -Path $stream.FullName | ConvertFrom-Json -Depth 20
    if ($streamJson.errors) {
        Write-Warning "The exported stream '$($stream.fullName)' is invalid. Skipping"
        continue
    }
    $streamObject = $streamJson.data.consume.stream

    Write-Host "Processing Stream: $($streamObject.name)" -ForegroundColor 'Cyan'

    $streamExists = $existingStreams | Where-Object { $_.name -eq $streamObject.name }
    switch ($StreamExists.count) {
        '0' {
            Write-Verbose "Creating Stream"
            $newStream = New-CluedInStream -Name $streamObject.name
            $streamId = $newStream.data.consume.createStream.id
            Write-Host "Created new stream $($streamId)" -ForegroundColor 'Cyan'
        }
        '1' {
            Write-Verbose "Stream Exists. Updating"
            $streamId = $streamExists.id
            Write-Host "Using existing stream $($streamId)" -ForegroundColor 'Cyan'
        }
        default { Write-Warning "Too many streams exist with name '$($streamObject.name)'"; continue }
    }

    Write-Verbose "Setting configuration"
    # The logic of streams has changed since 3.7.0[2023.07] to 4.0.0[2024.01]. Because of this,
    # configuration sitting on a new version needs the isActive property field
    if ([version]${env:CLUEDIN_CURRENTVERSION} -lt [version]'4.0.0') {
        if (!$streamObject.psobject.Properties.match('isActive').count) {
            $streamObject | Add-Member -MemberType NoteProperty -Name 'isActive' -Value ''
        }

        $streamObject.isActive = $false
    }

    $setResult = Set-CluedInStream -Id $streamId -Object $streamObject
    Check-ImportResult -Result $setResult
  
    $lookupConnectorId = $streamObject.connector.Id
    $connectorId = ($lookupConnectors | Where-Object { $_.OriginalConnectorId -eq $lookupConnectorId }).ConnectorId

    if($connectorId -eq $null)
    {
        $connectorId = $($streamObject.connector.Id)
        Write-Host "INFO: Export target '$($connectorId)' was not imported within this run"
    }
    
    $setStreamExportResult = Set-CluedInStreamExportTarget -Id $streamId -ConnectorProviderDefinitionId $connectorId -Object $streamObject
    Check-ImportResult -Result $setStreamExportResult
}



# Clean Projects
Write-Host "INFO: Importing Clean Projects" -ForegroundColor 'Green'
$cleanProjects = Get-ChildItem -Path $cleanProjectsPath -Filter "*.json" -Recurse
$currentCleanProjects = Get-CluedInCleanProjects
$currentCleanProjectsObject = $currentCleanProjects.data.preparation.allCleanProjects.projects

foreach ($cleanProject in $cleanProjects) {
    $cleanProjectJson = Get-Content -Path $cleanProject.FullName | ConvertFrom-Json -Depth 20
    $cleanProjectObject = $cleanProjectJson.data.preparation.cleanProjectDetail

    Write-Host "Processing Clean Project: $($cleanProjectObject.name)" -ForegroundColor 'Green'
    if ($cleanProjectObject.name -notin $currentCleanProjectsObject.name) {
        Write-Host "Creating Clean Project '$($cleanProjectObject.name)'" -ForegroundColor 'Cyan'
        $cleanProjectResult = New-CluedInCleanProject -Name $cleanProjectObject.name -Object $cleanProjectObject
        Check-ImportResult -Result $cleanProjectResult
        continue # No need to drift check on new creations
    }

    $cleanProjectId = ($currentCleanProjectsObject | Where-Object { $_.name -eq $cleanProjectObject.name }).id
    if ($cleanProjectId.count -ne 1) { Write-Error "Multiple Ids returned"; continue }

    Write-Host "Setting Configuration" -ForegroundColor 'Cyan'
    $setConfigurationResult = Set-CluedInCleanProject -Id $cleanProjectId -Object $cleanProjectObject
    Check-ImportResult -Result $setConfigurationResult

}

Import-DeduplicationProjects -RestorePath $RestorePath

Write-Host "INFO: Import Complete" -ForegroundColor 'Green'

if ($IncludeSupportFiles) {
    Write-Verbose "Copying JSON to support directory"
    Copy-Item -Path "$RestorePath/*" -Recurse -Destination $tempExportDirectory
    Stop-Transcript | Out-Null

    $zippedArchive = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('cluedin-support_{0}.zip' -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    Compress-Archive -Path "$tempExportDirectory" -DestinationPath "$zippedArchive" -Force
    Remove-Item -Path $tempExportDirectory -Recurse -Force

    Write-Host "Support files ready for sending '$zippedArchive'"
}



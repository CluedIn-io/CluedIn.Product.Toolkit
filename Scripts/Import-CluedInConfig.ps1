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

    .EXAMPLE
    PS> ./Import-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organization 'dev' -RestorePath /path/to/backups
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][Alias('Organisation')][string]$Organization,
    [Parameter(Mandatory)][string]$RestorePath,
    [switch]$UseHTTP
)

function checkResults($result) {
    if ($result.errors) {
        switch ($result.errors.message) {
            {$_ -match '409'} { Write-Warning "An entry already exists" }
            default { Write-Warning "Failed: $($result.errors.message)" }
        }
    }
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
$dataPath = Join-Path -Path $RestorePath -ChildPath 'Data'
$dataSourceSetsPath = Join-Path -Path $dataPath -ChildPath 'SourceSets'
$dataSourcesPath = Join-Path -Path $dataPath -ChildPath 'Sources'
$dataSetsPath = Join-Path -Path $dataPath -ChildPath 'Sets'
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
if (!(Test-Path -Path $dataSourceSetsPath, $dataSourcesPath, $dataSetsPath -PathType Container)) {
    throw "There as an issue finding '$dataPath' or sub-folders. Please investigate"
}

# Settings
$adminSettingsPath = Join-Path -Path $generalPath -ChildPath 'AdminSetting.json'
if (Test-Path -Path $adminSettingsPath -PathType Leaf) {
    Write-Host "INFO: Importing Admin Settings" -ForegroundColor 'Green'
    $restoreAdminSetting = Get-Content -Path $adminSettingsPath | ConvertFrom-Json -Depth 20

    $settings = ($restoreAdminSetting.data.administration.configurationSettings).psobject.properties.name
    $currentSettings = (Get-CluedInAdminSetting).data.administration.configurationSettings

    foreach ($setting in $settings) {
        $key = $setting

        if ($key -notin $currentSettings.psobject.properties.name) {
            Write-Verbose "Skipping '$key' as it's not a current setting"
            continue
        }

        $newValue = $restoreAdminSetting.data.administration.configurationSettings.$key
        $currentValue = $currentSettings.$key

        if ($newValue -ne $currentValue) {
            Write-Host "Processing Admin Setting '$key'. Was: $currentValue, Now: $newValue" -ForegroundColor 'Cyan'
            $adminSettingResult = Set-CluedInAdminSettings -Name $key -Value $newValue
            checkResults($adminSettingResult)
        }
    }
}

# Vocabulary
Write-Host "INFO: Importing Vocabularies" -ForegroundColor 'Green'
$restoreVocabularies = Get-ChildItem -Path $vocabPath -Filter "*.json"

foreach ($vocabulary in $restoreVocabularies) {
    $vocabJson = Get-Content -Path $vocabulary.FullName | ConvertFrom-Json -Depth 20
    $vocabObject = $vocabJson.data.management.vocabulary

    Write-Host "Processing Vocab: $($vocabObject.vocabularyName) ($($vocabObject.vocabularyId))" -ForegroundColor 'Cyan'
    Write-Debug "$($vocabObject | Out-String)"

    $entityTypeResult = Get-CluedInEntityType -Search $($vocabObject.entityTypeConfiguration.displayName)
    if ($entityTypeResult.data.management.entityTypeConfigurations.total -ne 1) {
        $entityResult = New-CluedInEntityType -Object $vocabObject.entityTypeConfiguration
        checkResults($entityResult)
    }

    $exists = (Get-CluedInVocabulary -Search $vocabObject.vocabularyName -HardMatch).data.management.vocabularies.data
    if (!$exists) {
        $vocabResult = New-CluedInVocabulary -Object $vocabObject
        checkResults($vocabResult)
    }
    else {
        if ($exists.count -ne 1) { Write-Warning "Issue with following:`n$exists. Only 1 should have been returned"; continue }

        # We have to get again because the `exists` section doesn't pull the configuration. Just metadata.
        $currentVocab = (Get-CluedInVocabularyById -Id $exists.vocabularyId).data.management.vocabulary
        $vocabObject.vocabularyId = $currentVocab.vocabularyId # These cannot be updated once set
        $vocabObject.vocabularyName = $currentVocab.vocabularyName # These cannot be updated once set
        $vocabObject.keyPrefix = $currentVocab.keyPrefix # These cannot be updated once set

        Write-Verbose "'$($vocabObject.vocabularyName)' already exists, overwriting existing configuration"
        Write-Verbose "Restored Config`n$($vocabObject | Out-String)"
        Write-Verbose "Current Config`n$($currentVocab | Out-String)"
        $vocabUpdateResult = Set-CluedInVocabulary -Object $vocabObject
        checkResults($vocabUpdateResult)
    }
}

Write-Host "INFO: Importing Vocabulary Keys" -ForegroundColor 'Green'
$vocabKeys = Get-ChildItem -Path $vocabKeysPath -Filter "*.json"
foreach ($vocabKey in $vocabKeys) {
    $vocabKeyJson = Get-Content -Path $vocabKey.FullName | ConvertFrom-Json -Depth 20
    $vocabKeyObject = $vocabKeyJson.data.management.vocabularyKeysFromVocabularyId.data

    $vocabName = $vocabKeyObject.vocabulary.vocabularyName | Select-Object -First 1
    $vocabulary = Get-CluedInVocabulary -Search $vocabName -IncludeCore -HardMatch
    $vocabularyId = $vocabulary.data.management.vocabularies.data.vocabularyId
    foreach ($key in $vocabKeyObject) {
        if ($key.isObsolete) { Write-Verbose "Not importing: '$($key.key)' as it's obsolete"; continue }

        Write-Host "Processing Vocab Key: $($key.displayName) ($($key.vocabularyKeyId))" -ForegroundColor 'Cyan'
        Write-Debug "$($key | Out-String)"

        $currentKeys = Get-CluedInVocabularyKey -Id $vocabularyId
        $currentKeysObject = $currentKeys.data.management.vocabularyKeysFromVocabularyId.data
        $currentVocabularyKeyObject = $currentKeysObject | Where-Object { $_.key -eq $key.key }

        if ($key.mapsToOtherKeyId) {
            $mappedKeyId = Get-CluedInVocabularyKey -Search $key.mappedKey.key
            $key.mapsToOtherKeyId = $mappedKeyID ?
                $mappedKeyId.data.management.vocabularyPerKey.vocabularyKeyId :
                $null
        }

        if (!$currentVocabularyKeyObject.key) {
            Write-Host "Creating '$($key.key)' as it doesn't exist" -ForegroundColor 'DarkCyan'
            $params = @{
                Object = $key
                VocabId = $vocabulary.data.management.vocabularies.data.vocabularyId
            }
            $vocabKeyResult = New-CluedInVocabularyKey @params
            checkResults($vocabKeyResult)

            if ($?) {
                $key.vocabularyId = $vocabKeyResult.data.management.createVocabularyKey.vocabularyId
                $key.vocabularyKeyId = $vocabKeyResult.data.management.createVocabularyKey.vocabularyKeyId
            }
        }
        else {
            $key.vocabularyKeyId = $currentVocabularyKeyObject.vocabularyKeyId # These cannot be updated once set
            $key.vocabularyId = $currentVocabularyKeyObject.vocabularyId # These cannot be updated once set
            $key.name = $currentVocabularyKeyObject.name # These cannot be updated once set

            Write-Verbose "'$($key.key)' exists, overwriting existing configuration"
            $vocabKeyUpdateResult = Set-CluedInVocabularyKey -Object $key
            checkResults($vocabKeyUpdateResult)
        }

        if ($key.mapsToOtherKeyId) {
            Write-Verbose "Processing Vocabulary Key Mapping"
            $keyLookup = Get-CluedInVocabularyKey -Search $key.mappedKey.key
            $keyLookupId = $keyLookup.data.management.vocabularyPerKey.vocabularyKeyId

            if ($keyLookupId) {
                Write-Host "Setting Vocab Key mapping '$($key.key)' to '$($key.mappedKey.key)'" -ForegroundColor 'DarkCyan'
                $mapResult = Set-CluedInVocabularyKeyMapping -Source $key.vocabularyKeyId -Destination $keyLookupId
                checkResults($mapResult)
            }
        }
    }
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
    if (!$dataSourceSetMatch) {
        $dataSourceSetResult = New-CluedInDataSourceSet -DisplayName $dataSourceSetName
        checkResults($dataSourceSetResult)
        $dataSourceSetMatch = (Get-CluedInDataSourceSet -Search $dataSourceSetName).data.inbound.dataSourceSets.data
    }
    $dataSourceObject.dataSourceSet.id = $dataSourceSetMatch.id

    Write-Host "Processing Data Source: $($dataSourceObject.name) ($($dataSourceObject.id))" -ForegroundColor 'Cyan'
    $exists = (Get-CluedInDataSource -Search $dataSourceObject.name).data.inbound.dataSource
    if (!$exists) {
        Write-Host "Creating '$($dataSourceObject.name)' as it doesn't exist" -ForegroundColor 'DarkCyan'
        $dataSourceResult = New-CluedInDataSource -Object $dataSourceObject
        checkResults($dataSourceResult)
    }
    $dataSourceId = $exists.id ?? $dataSourceResult.data.inbound.createDataSource.id

    Write-Host "Updating Configuration for $($dataSourceObject.name)" -ForegroundColor 'Cyan'
    $dataSourceObject.connectorConfiguration.id =
        (Get-CluedInDataSource -Search $dataSourceObject.name).data.inbound.dataSource.connectorConfiguration.id
    $dataSourceObject.connectorConfiguration.configuration.DataSourceId = $dataSourceId
    $dataSourceConfigResult = Set-CluedInDataSourceConfiguration -Object $dataSourceObject.connectorConfiguration
    checkResults($dataSourceConfigResult)
}

Write-Host "INFO: Importing Data Sets" -ForegroundColor 'Green'
$dataSets = Get-ChildItem -Path $dataSetsPath -Filter "*-DataSet.json"

foreach ($dataSet in $dataSets) {
    $dataSetJson = Get-Content -Path $dataSet.FullName | ConvertFrom-Json -Depth 20
    $dataSetObject = $dataSetJson.data.inbound.dataSet
    Write-Host "Processing Data Set: $($dataSetObject.name) ($($dataSetObject.id))" -ForegroundColor 'Cyan'

    if ($dataSetObject.dataSource.type -eq 'file') {
        Write-Warning "Importing of 'file' type data sets are not supported. Only endpoints are. Skipping import."
        continue
    }

    $dataSource = Get-CluedInDataSource -Search $dataSetObject.dataSource.name
    if (!$dataSource) { Write-Warning "Data Source '$($dataSetObject.dataSource.name)' not found"; continue }
    $dataSetObject.dataSource.id = $dataSource.data.inbound.dataSource.id

    # If this gets passed in as a null (ie. Not an empty array), it will cause issues when hitting the database.
    # The below ensures that if it is a null, it'll at least be an empty array.
    if (!$dataSetObject.originalFields) { $dataSetObject.originalFields = @() }

    $exists = ($dataSetObject.name -in $dataSource.data.inbound.dataSource.dataSets.name)
    if (!$exists) {
        # Force autoSubmit to false as we don't want it to process automatically when transferred
        $dataSetObject.configuration.object.autoSubmit = $false

        Write-Host "Creating '$($dataSetObject.name)' as it doesn't exist" -ForegroundColor 'DarkCyan'
        $dataSetResult = New-CluedInDataSet -Object $dataSetObject
        checkResults($dataSetResult)
        $dataSetId = $dataSetResult.data.inbound.createDataSets.id

        if ($dataSetObject.dataSource.type -eq 'endpoint') {
            $endpoint = '{0}/upload/api/endpoint/{1}' -f ${env:CLUEDIN_ENDPOINT}, $dataSetId
            Write-Host "New Endpoint created: $endPoint"
        }
    }

    Write-Host "Updating Annotations for $($dataSetObject.name)" -ForegroundColor 'Cyan'
    $annotationPath = Join-Path -Path $dataSetsPath -ChildPath ('{0}-Annotation.json' -f $dataSetObject.id)
    if (!(Test-Path -Path $annotationPath -PathType 'Leaf')) { Write-Warning "No annotation to import"; continue }

    Try {
        $annotationJson = Get-Content -Path $annotationPath | ConvertFrom-Json -Depth 20
        $annotationObject = $annotationJson.data.preparation.annotation

        $vocabName = $annotationObject.vocabulary.vocabularyName
        $vocabSearchResult = Get-CluedInVocabulary -Search $vocabName -IncludeCore -HardMatch
        $vocabObject = $vocabSearchResult.data.management.vocabularies.data

        $keyToMatch = $annotationObject.vocabulary.keyPrefix
        $vocabObject = $vocabObject | Where-Object { $_.keyPrefix -eq $keyToMatch }

        if (!$vocabObject.count -eq 1) {
            Write-Error "There was an issue getting vocab '${vocabName}'"
            Write-Debug $($vocabObject | Out-String)
            continue
        }

        $annotationObject.vocabulary.vocabularyId = $vocabObject.vocabularyId

        $dataSourceObject = (Get-CluedInDataSource -Search $dataSetObject.dataSource.name).data.inbound.dataSource
        $destinationDataSetObject = $dataSourceObject.dataSets | Where-Object { $_.name -eq $dataSetObject.name }
        $dataSetId = $destinationDataSetObject.id
        if (!$dataSetId) { Write-Error "Issue getting dataSetId"; continue }

        $annotationId = $destinationDataSetObject.annotation.id
        if (!$annotationId) {
            Write-Host "Creating Annotation"
            $annotationResult = New-CluedInAnnotation -Object $annotationObject -DataSetId $dataSetId
            checkResults($annotationResult)

            $annotationId = (Get-CluedInDataSet -id $dataSetId).data.inbound.dataSet.annotationId
        }

        Write-Verbose "Setting Annotation Configuration"
        $annotationObject.id = $annotationId
        $setAnnotationResult = Set-CluedInAnnotation -Id $annotationObject.id -Object $annotationObject
        checkResults($setAnnotationResult)

        Write-Verbose "Configuring Mappings"
        if (!$dataSetObject.fieldMappings) { Write-Warning "No field mappings detected." }

        foreach ($mapping in $dataSetObject.fieldMappings) {
            Write-Host "Processing field mapping: $($mapping.originalField)" -ForegroundColor 'Cyan'
            $currentFieldMappings = (Get-CluedInDataSet -Id $dataSetId).data.inbound.dataSet.fieldMappings

            switch ($mapping.key) {
                '--ignore--' {
                    if ($mapping.originalField -notin $currentFieldMappings.originalField) {
                        $dataSetMappingParams = @{
                            Object = $mapping
                            DataSetId = $dataSetId
                            IgnoreField = $true
                        }
                        $dataSetMappingResult = New-CluedInDataSetMapping @dataSetMappingParams
                    }
                    else {
                        $currentMappingObject = $currentFieldMappings | Where-Object { $_.originalField -eq $mapping.originalField }
                        $mappingParams = @{
                            DataSetId = $dataSetId
                            PropertyMappingConfiguration = @{
                                originalField = $currentMappingObject.originalField
                                key = '--ignore--'
                                id = $currentMappingObject.id
                            }
                        }
                        $dataSetMappingResult = Set-CluedInDataSetMapping @mappingParams
                    }
                    checkResults($dataSetMappingResult)
                }
                default {
                    $fieldVocabKey = Get-CluedInVocabularyKey -Search $mapping.key
                    $fieldVocabKeyObject = $fieldVocabKey.data.management.vocabularyPerKey
                    if (!$fieldVocabKeyObject.vocabularyKeyId) {
                        Write-Warning "Key: $($mapping.key) doesn't exist. Mapping will be skipped for '$($mapping.originalField)'"
                        continue
                    }

                    if ($mapping.originalField -notin $currentFieldMappings.originalField) {
                        $mapping.key = $fieldVocabKeyObject.key # To cover case sensitive process

                        $dataSetMappingParams = @{
                            Object = $mapping
                            DataSetId = $dataSetId
                            VocabularyKeyId = $fieldVocabKeyObject.vocabularyKeyId
                            VocabularyId = $fieldVocabKeyObject.vocabularyId
                        }

                        $dataSetMappingResult = New-CluedInDataSetMapping @dataSetMappingParams
                    }
                    else {
                        $currentMappingObject = $currentFieldMappings | Where-Object { $_.originalField -eq $mapping.originalField }

                        $desiredAnnotation = $annotationObject.annotationProperties | Where-Object { $_.vocabKey -ceq $mapping.key }
                        if (!$desiredAnnotation) { Write-Warning "Issue finding the desired annotation. Skipping map"; continue }

                        $propertyMappingConfiguration = @{
                            originalField = $currentMappingObject.originalField
                            id = $currentMappingObject.id
                            useAsAlias = $desiredAnnotation.useAsAlias
                            useAsEntityCode = $desiredAnnotation.useAsEntityCode
                            vocabularyKeyConfiguration = @{
                                vocabularyId = $fieldVocabKeyObject.vocabularyId
                                new = $false
                                vocabularyKeyId = $fieldVocabKeyObject.vocabularyKeyId
                            }
                        }

                        $dataSetMappingsParams = @{
                            DataSetId = $dataSetId
                            PropertyMappingConfiguration = $propertyMappingConfiguration
                        }

                        $dataSetMappingResult = Set-CluedInDataSetMapping @dataSetMappingsParams
                    }
                    checkResults($dataSetMappingResult)
                }
            }
        }

        Write-Verbose "Setting Annotation Entity Codes"
        $entities = $annotationObject.annotationProperties | Where-Object { $_.useAsEntityCode }
        foreach ($entity in $entities) {
            $setAnnotationEntityCodesResult = Set-CluedInAnnotationEntityCodes -Object $entity -Id $annotationObject.id
            checkResults($setAnnotationEntityCodesResult)
        }

        # Blocked as not currently in scope

        # Write-Verbose "Adding Edge Mappings"
        # $edges = $annotationObject.annotationProperties | Where-Object {$_.annotationEdges}

        # foreach ($edge in $edges) {
        #     $edge = $edge.annotationEdges
        #     $edgeVocabulary = Get-CluedInVocabularyKey -Search $edge.edgeProperties.vocabularyKey.key
        #     $edgeVocabularyObject = $edgeVocabulary.data.management.vocabularyPerKey
        #     $edge.edgeProperties.vocabularyKey.vocabularyKeyId = $edgeVocabularyObject.vocabularyKeyId
        #     $edge.edgeProperties.vocabularyKey.vocabularyId = $edgeVocabularyObject.vocabularyId

        #     $edgeResult = New-CluedInEdgeMapping -Object $edge -AnnotationId $annotationObject.id
        #     checkResults($edgeResult)
        # }
    }
    catch {
        Write-Verbose "Annotation file '$annotationPath' not found or error occured during run"
        Write-Debug $_
        continue
    }
}

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
        checkResults($ruleResult)
        $ruleObject.id = $ruleResult.data.management.createRule.id
    }
    else { $ruleObject.id = $exists.data.management.rules.data.id }

    Write-Verbose "Setting rule configuration"
    $setRuleResult = Set-CluedInRule -Object $ruleObject
    checkResults($setRuleResult)
}

# Export Targets
Write-Host "INFO: Importing Export Targets" -ForegroundColor 'Green'
$exportTargets = Get-ChildItem -Path $exportTargetsPath -Filter "*.json" -Recurse
$installedExportTargets = (Get-CluedInInstalledExportTargets).data.inbound.connectors

$cleanProperties = @(
    'connectinString', 'password', 'host'
    'AccountKey', 'AccountName', 'authorization'
)

foreach ($target in $exportTargets) {
    $targetJson = Get-Content -Path $target.FullName | ConvertFrom-Json -Depth 20
    $targetObject = $targetJson.data.inbound.connectorConfiguration
    $targetProperties = ($targetObject.helperConfiguration | Get-Member -MemberType 'NoteProperty').Name

    Write-Host "Processing Export Target: $($targetObject.accountId)" -ForegroundColor 'Cyan'

    if (!$targetObject.accountId) {
        Write-Warning "Account Id is null, cannot compare. Skipping."
        Write-Host "You will need to manually add the '$($targetObject.name)' connector"
        continue
    }

    $cleanProperties.ForEach({
        if ($_ -in $targetProperties) { $targetObject.helperConfiguration.$_ = $null }
    })

    # We should constantly get latest as we may create a new one in prior iteration.
    $currentExportTargets = (Get-CluedInExportTargets).data.inbound.connectorConfigurations.configurations

    $targetExists = $targetObject.accountId -in $currentExportTargets.accountId
    if (!$targetExists) {
        if ($targetObject.providerId -notin $installedExportTargets.id) {
            Write-Warning "Export Target '$($targetObject.connector.name)' could not be found. Skipping creation."
            Write-Warning "Please install connector and try again"
            continue
        }

        Write-Verbose "Creating Export Target"
        $targetResult = New-CluedInExportTarget -ConnectorId $targetObject.providerId -Configuration $targetObject.helperConfiguration
        checkResults($targetResult)

        $id = $targetResult.data.inbound.createConnection.id
    }
    else {
        Write-Verbose "Export target exists. Setting configuration"
        $id = ($currentExportTargets | Where-Object {$_.accountId -eq $targetObject.accountId}).id
        $setTargetResult = Set-CluedInExportTargetConfiguration -Id $id -Configuration $targetObject.helperConfiguration
        checkResults($setTargetResult)
    }

    Write-Verbose "Setting Permissions"
    $currentTarget = (Get-CluedInExportTarget -Id $id).data.inbound.connectorConfiguration
    $usersToAdd = Compare-Object -ReferenceObject $currentTarget.users.username -DifferenceObject $targetObject.users.username -PassThru |
        Where-Object {$_.SideIndicator -eq '=>'}

    $idsToSet = @()
    foreach ($user in $usersToAdd) {
        $idsToSet += ($allUsers | Where-Object {$_.account.UserName -eq $user}).id
    }

    if ($idsToSet) { Set-CluedInExportTargetPermissions -ConnectorId $id -UserId $idsToSet }
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
        }
        '1' {
            Write-Verbose "Stream Exists. Updating"
            $streamId = $streamExists.id
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
    checkResults($setResult)

    $setStreamExportResult = Set-CluedInStreamExportTarget -Id $streamId -Object $streamObject
    checkResults($setStreamExportResult)
}

# Glossaries
Write-Host "INFO: Importing Glossaries" -ForegroundColor 'Green'
$glossaries = Get-ChildItem -Path $glossariesPath -Directory -ErrorAction 'SilentlyContinue'

$currentGlossaries = Get-CluedInGlossary
$currentGlossariesObject = $currentGlossaries.data.management.glossaryCategories

$currentTerms = Get-CluedInGlossaryTerms
$currentTermsObject = $currentTerms.data.management.glossaryTerms.data

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
        checkResults($glossaryResult)

        $glossaryId = $glossaryResult.data.management.createGlossaryCategory.id
    }

    $glossaryId = $glossaryId ??
        ($currentGlossariesObject |
            Where-Object { $_.name -eq $glossaryObject.name }).id

    Write-Verbose "Processing Terms"
    foreach ($term in $termsFile) {
        $termId = $null
        $termJson = Get-Content -Path $term.FullName | ConvertFrom-Json -Depth 20
        $termObject = $termJson.data.management.glossaryTerm

        Write-Host "Processing Term: $($termObject.name)" -ForegroundColor 'Cyan'
        if ($termObject.name -notin $currentTermsObject.name) {
            Write-Host "Creating Term '$($termObject.name)'" -ForegroundColor 'DarkCyan'
            $termResult = New-CluedInGlossaryTerm -Name $termObject.name -GlossaryId $glossaryId
            checkResults($termResult)

            $termId = $termResult.data.management.createGlossaryTerm.id
        }

        $termId = $termId ??
            ($currentTermsObject |
                Where-Object { $_.name -eq $termObject.name }).id

        Write-Verbose "Setting term configuration"
        $setTermResult = Set-CluedInGlossaryTerm -Id $termId -Object $termObject
        checkResults($setTermResult)
    }
}

# Clean Projects
Write-Host "INFO: Importing Glossaries" -ForegroundColor 'Green'
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
        checkResults($cleanProjectResult)
        continue # No need to drift check on new creations
    }

    $cleanProjectId = ($currentCleanProjectsObject | Where-Object { $_.name -eq $cleanProjectObject.name }).id
    if ($cleanProjectId.count -ne 1) { Write-Error "Multiple Ids returned"; continue }

    Write-Host "Setting Configuration" -ForegroundColor 'Cyan'
    $setConfigurationResult = Set-CluedInCleanProject -Id $cleanProjectId -Object $cleanProjectObject
    checkResults($setConfigurationResult)
}

Write-Host "INFO: Import Complete" -ForegroundColor 'Green'
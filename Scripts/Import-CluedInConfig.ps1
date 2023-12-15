<#
    .SYNOPSIS
    Imports configuration to the connected environment by using backups

    .DESCRIPTION
    Imports configuration to the connected environment by using backups

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL
    This is the base url of your clued in instance. If you access CluedIn by https://cluedin.domain.com, the BaseURL is 'domain.com'

    .PARAMETER Organisation
    This is the section before your base URL. If you access CluedIn by https://cluedin.domain.com, the Organisation is 'cluedin'

    .PARAMETER Version
    This is the version of your current CluedIn environment in the format of '2023.01'

    .PARAMETER RestorePath
    This is the location of the export files ran by Export-CluedInConfig

    .EXAMPLE
    PS> ./Import-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organisation 'dev' -Version '2023.07' -RestorePath /path/to/backups
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][string]$Organisation,
    [Parameter(Mandatory)][version]$Version,
    [Parameter(Mandatory)][string]$RestorePath
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
Write-Host "INFO: Importing Admin Settings" -ForegroundColor 'Green'
$restoreAdminSetting = Get-Content -Path (Join-Path -Path $generalPath -ChildPath 'AdminSetting.json') | ConvertFrom-Json -Depth 20

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
    $vocabulary = Get-CluedInVocabulary -Search $vocabName -IncludeCore
    foreach ($key in $vocabKeyObject) {
        Write-Host "Processing Vocab Key: $($key.displayName) ($($key.vocabularyKeyId))" -ForegroundColor 'Cyan'
        Write-Debug "$($key | Out-String)"

        $currentVocabularyKey = Get-CluedInVocabularyKey -Search $key.key
        $currentVocabularyKeyObject = $currentVocabularyKey.data.management.vocabularyPerKey
        if (!$currentVocabularyKeyObject.key) {
            Write-Host "Creating '$($key.key)' as it doesn't exist" -ForegroundColor 'DarkCyan'
            $params = @{
                Object = $key
                VocabId = $vocabulary.data.management.vocabularies.data.vocabularyId
            }
            $vocabKeyResult = New-CluedInVocabularyKey @params
            checkResults($vocabKeyResult)
        }
        else {
            $key.vocabularyKeyId = $currentVocabularyKeyObject.vocabularyKeyId # These cannot be updated once set
            $key.vocabularyId = $currentVocabularyKeyObject.vocabularyId # These cannot be updated once set
            $key.name = $currentVocabularyKeyObject.name # These cannot be updated once set

            Write-Verbose "'$($key.key)' exists, overwriting existing configuration"
            $vocabKeyUpdateResult = Set-CluedInVocabularyKey -Object $key
            checkResults($vocabKeyUpdateResult)
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

    $dataSource = Get-CluedInDataSource -Search $dataSetObject.dataSource.name
    if (!$dataSource) { Write-Warning "Data Source '$($dataSetObject.dataSource.name)' not found"; continue}
    $dataSetObject.dataSource.id = $dataSource.data.inbound.dataSource.id

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
        $settings = @{
            useDefaultSourceCode = $annotationObject.useDefaultSourceCode
            useStrictEdgeCode = $annotationObject.useStrictEdgeCode
            descriptionKey = $annotationObject.descriptionKey
            nameKey = $annotationObject.nameKey
            originEntityCodeKey = $annotationObject.originEntityCodeKey
            origin = $annotationObject.origin
        }
        $setAnnotationResult = Set-CluedInAnnotation -Id $annotationObject.id -Settings $settings
        checkResults($setAnnotationResult)

        Write-Verbose "Configuring Mappings"
        if (!$dataSetObject.fieldMappings) { Write-Warning "No field mappings detected." }
        else { $currentFieldMappings = (Get-CluedInDataSet -Id $dataSetId).data.inbound.dataSet.fieldMappings }

        foreach ($mapping in $dataSetObject.fieldMappings) {
            $skipCreation = $false
            if ($mapping.originalField -notin $currentFieldMappings.originalField) {
                Write-Host "Creating field mapping '$($mapping.originalField)'" -ForegroundColor 'Cyan'
                switch ($mapping.key) {
                    '--ignore--' {
                        $dataSetMappingParams = @{
                            Object = $mapping
                            DataSetId = $dataSetId
                            IgnoreField = $true
                        }
                    }
                    default {
                        $vocabularyKey = Get-CluedInVocabularyKey -Search $mapping.key
                        $vocabularyKeyObject = $vocabularyKey.data.management.vocabularyPerKey
                        if (!$vocabularyKeyObject.vocabularyKeyId) {
                            Write-Warning "Key: $($mapping.key) doesn't exist. Mapping will be skipped for '$($mapping.originalField)'"
                            $skipCreation = $true; continue
                        }

                        $dataSetMappingParams = @{
                            Object = $mapping
                            DataSetId = $dataSetId
                            VocabularyKeyId = $vocabularyKeyObject.vocabularyKeyId
                            VocabularyId = $vocabularyKeyObject.vocabularyId
                        }
                    }
                }

                if ($skipCreation) { continue }
                $dataSetMappingResult = New-CluedInDataSetMapping @dataSetMappingParams
                checkResults($dataSetMappingResult)
            }
            else {
                $currentMappingObject = $currentFieldMappings | Where-Object {$_.originalField -eq $mapping.originalField}
                $currentKey = $currentMappingObject.key
                if (!($mapping.key -eq $currentKey)) {
                    Write-Host "Updating field mapping '$($mapping.originalField)' as there is drift" -ForegroundColor 'Yellow'
                    $dataSetMappingsParams = @{
                        DataSetId = $dataSetId
                        FieldMappings = @{
                            originalField = $mapping.originalField
                            key = $mapping.key
                            id = $currentMappingObject.id
                        }
                    }
                    $dataSetMappingResult = Set-CluedInDataSetMapping @dataSetMappingsParams
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

Write-Host "INFO: Import Complete" -ForegroundColor 'Green'
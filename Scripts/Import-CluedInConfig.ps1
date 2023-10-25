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
$adminSetting = Get-Content -Path (Join-Path -Path $generalPath -ChildPath 'AdminSetting.json') | ConvertFrom-Json -Depth 20

$settings = ($adminSetting.data.administration.configurationSettings).psobject.properties.name

foreach ($setting in $settings) {
    # We apparently export API keys which need to be re-imported.
    # Need to find out where these are grabbed from and we can then store/retrieve from KV

    $key = $setting
    $value = $adminSetting.data.administration.configurationSettings.$key
    Write-Host "Processing Admin Setting: $key" -ForegroundColor 'Cyan'
    $adminSettingResult = Set-CluedInAdminSettings -AdminSettingName $key -AdminSettingValue $value
    checkResults($adminSettingResult)
}

# Vocabulary
Write-Host "INFO: Importing Vocabularies" -ForegroundColor 'Green'
$vocabularies = Get-ChildItem -Path $vocabPath -Filter "*.json"
foreach ($vocabulary in $vocabularies) {
    $vocabJson = Get-Content -Path $vocabulary.FullName | ConvertFrom-Json -Depth 20
    $vocabObject = $vocabJson.data.management.vocabulary

    Write-Host "Processing Vocab: $($vocabObject.vocabularyName) ($($vocabObject.vocabularyId))" -ForegroundColor 'Cyan'
    Write-Debug "$($vocabObject | Out-String)"

    # Check if entity Type exists and create if not found
    $entityTypeResult = Get-CluedInEntityType -Search $($vocabObject.entityTypeConfiguration.displayName)
    if ($entityTypeResult.data.management.entityTypeConfigurations.total -ne 1) {
        $entityResult = New-CluedInEntityType -Object $vocabObject.entityTypeConfiguration
        checkResults($entityResult)
    }

    $vocabResult = New-CluedInVocabulary -Object $vocabObject
    checkResults($vocabResult)
}

Write-Host "INFO: Importing Vocabulary Keys" -ForegroundColor 'Green'
Write-Host "This may take a couple minutes..." -ForegroundColor 'Yellow'
$vocabKeys = Get-ChildItem -Path $vocabKeysPath -Filter "*.json"
foreach ($vocabKey in $vocabKeys) {
    $vocabKeyJson = Get-Content -Path $vocabKey.FullName | ConvertFrom-Json -Depth 20
    $vocabKeyObject = $vocabKeyJson.data.management.vocabularyKeysFromVocabularyId.data

    $vocabName = $vocabKeyObject.vocabulary.vocabularyName | Select-Object -First 1
    $vocabulary = Get-CluedInVocabulary -Search $vocabName -IncludeCore
    foreach ($key in $vocabKeyObject) {
        Write-Host "Processing Vocab Key: $($key.displayName) ($($key.vocabularyKeyId))" -ForegroundColor 'Cyan'
        Write-Debug "$($key | Out-String)"

        $vocabularyKey = Get-CluedInVocabularyKey -Search $key.key
        if (!$vocabularyKey.data.management.vocabularyPerKey.key) {
            Write-Host "Creating '$($key.key)' as it doesn't exist" -ForegroundColor 'DarkCyan'
            $params = @{
                Object = $key
                VocabId = $vocabulary.data.management.vocabularies.data.vocabularyId
            }
            $vocabKeyResult = New-CluedInVocabularyKey @params
            checkResults($vocabKeyResult)
        }
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
        Write-Host "Creating '$($dataSourceSet.name)' as it doesn't exist" -ForegroundColor 'DarkCyan'
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
        Write-Host "Creating '$($dataSourceObject.name)' as it doesn't exist" -ForegroundColor 'DarkCyan'
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
        Write-Host "Creating '$($dataSetObject.name)' as it doesn't exist" -ForegroundColor 'DarkCyan'
        $dataSetResult = New-CluedInDataSet -Object $dataSetObject
        checkResults($dataSetResult)

        if ($dataSetObject.dataSource.type -eq 'endpoint') {
            $dataSetId = $dataSetResult.data.inbound.createDataSets.id
            $endpoint = '{0}/upload/api/endpoint/{1}' -f ${env:CLUEDIN_ENDPOINT}, $dataSetId
            Write-Host "New Endpoint created: $endPoint"

            # If the dataSet already exists, we need to assume the annotations were also restored.
            # So we only run this in the !exists block
            Write-Host "Processing Annotations" -ForegroundColor Cyan
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

                Write-Host "Creating annotation as it doesn't exist" -ForegroundColor 'DarkCyan'
                $annotationResult = New-CluedInAnnotation -Object $annotationObject
                checkResults($annotationResult)

                Write-Verbose "Setting Annotation Configuration"
                $annotationId = (Get-CluedInDataSet -id $dataSetId).data.inbound.dataSet.annotationId # Doesn't come from result
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
                foreach ($mapping in $dataSetObject.fieldMappings) {
                    $vocabularyKey = Get-CluedInVocabularyKey -Search $mapping.key
                    $vocabularyKeyObject = $vocabularyKey.data.management.vocabularyPerKey
                    if (!$vocabularyKeyObject.vocabularyKeyId) {
                        Write-Error "Key: $($mapping.key) doesn't exist"
                        continue
                    }

                    $mapping | Add-Member -MemberType 'NoteProperty' -Name 'dataSetId' -Value $dataSetId
                    $mapping | Add-Member -MemberType 'NoteProperty' -Name 'vocabularyId' -Value $vocabularyKeyObject.vocabularyId
                    $mapping | Add-Member -MemberType 'NoteProperty' -Name 'vocabularyKeyId' -Value $vocabularyKeyObject.vocabularyKeyId

                    $dataSetMappingResult = New-CluedInDataSetMapping -Object $mapping
                    checkResults($dataSetMappingResult)
                }

                Write-Verbose "Setting Annotation Entity Codes"
                $entities = $annotationObject.annotationProperties | Where-Object {$_.useAsEntityCode}
                foreach ($entity in $entities) {
                    $setAnnotationEntityCodesResult = Set-CluedInAnnotationEntityCodes -Object $entity -Id $annotationObject.id
                    checkResults($setAnnotationEntityCodesResult)
                }

                Write-Verbose "Adding Edge Mappings"
                $edges = $annotationObject.annotationProperties | Where-Object {$_.annotationEdges}

                foreach ($edge in $edges) {
                    $edge = $edge.annotationEdges
                    $edgeVocabulary = Get-CluedInVocabularyKey -Search $edge.edgeProperties.vocabularyKey.key
                    $edgeVocabularyObject = $edgeVocabulary.data.management.vocabularyPerKey
                    $edge.edgeProperties.vocabularyKey.vocabularyKeyId = $edgeVocabularyObject.vocabularyKeyId
                    $edge.edgeProperties.vocabularyKey.vocabularyId = $edgeVocabularyObject.vocabularyId

                    $edgeResult = New-CluedInEdgeMapping -Object $edge -AnnotationId $annotationObject.id
                    checkResults($edgeResult)
                }
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

# Rules
Write-Host "INFO: Importing Rules" -ForegroundColor 'Green'
$rules = Get-ChildItem -Path $rulesPath -Filter "*.json" -Recurse
foreach ($rule in $rules) {
    $ruleJson = Get-Content -Path $rule.FullName | ConvertFrom-Json -Depth 20
    $ruleObject = $ruleJson.data.management.rule

    Write-Host "Processing Rule: $($ruleObject.name) ($($ruleObject.scope))" -ForegroundColor 'Cyan'
    $ruleResult = New-CluedInRule -Name $ruleObject.name -Scope $ruleObject.scope
    checkResults($ruleResult)

    Write-Verbose "Setting rule configuration"
    $ruleObject.id = $ruleResult.data.management.createRule.id
    $setRuleResult = Set-CluedInRule -Object $ruleObject
    checkResults($setRuleResult)
}

Write-Host "INFO: Import Complete" -ForegroundColor 'Green'
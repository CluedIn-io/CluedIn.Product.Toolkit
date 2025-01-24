function Import-DataSets{
    <#
        .SYNOPSIS
        Imports data sets and annotations

        .DESCRIPTION
        Imports data sets and annotations

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-DataSets -RestorePath "c:\backuplocation"

        This will import all of the data sets and their related annotation data
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )

    $dataSetsPath = Join-Path -Path $RestorePath -ChildPath 'Data/Sets'

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
            Check-ImportResult -Result $dataSetResult
            $dataSetId = $dataSetResult.data.inbound.createDataSets.id

            if ($dataSetObject.dataSource.type -eq 'endpoint') {
                $endpoint = '{0}/upload/api/endpoint/{1}' -f ${env:CLUEDIN_ENDPOINT}, $dataSetId
                Write-Host "New Endpoint created: $endPoint"
            }
        }

        Write-Host "Updating Annotations for $($dataSetObject.name)" -ForegroundColor 'Cyan'
        $annotationPath = Join-Path -Path $dataSetsPath -ChildPath ('{0}-Annotation.json' -f $dataSetObject.id)
        if (!(Test-Path -Path $annotationPath -PathType 'Leaf')) { Write-Warning "No annotation to import"; continue }

        $lookupAnnotations = @()
        Try {
            $annotationJson = Get-Content -Path $annotationPath | ConvertFrom-Json -Depth 20
            $annotationObject = $annotationJson.data.preparation.annotation

            $vocabName = $annotationObject.vocabulary.vocabularyName
            $vocabSearchResult = Get-CluedInVocabulary -Search $vocabName -IncludeCore -HardMatch
            $vocabObject = $vocabSearchResult.data.management.vocabularies.data

            $keyToMatch = $annotationObject.vocabulary.keyPrefix
            $vocabObject = $vocabObject | Where-Object { $_.keyPrefix -eq $keyToMatch }

            if (!$vocabObject.count -eq 1) {
                Write-Warning "There was an issue getting vocab '${vocabName}', please ensure it was exported correctly"
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
                Check-ImportResult -Result $annotationResult

                $annotationId = (Get-CluedInDataSet -id $dataSetId).data.inbound.dataSet.annotationId
            }

            $lookupAnnotations += [PSCustomObject]@{
                OriginalAnnotationId = $annotationObject.id
                AnnotationId = $annotationId
            }

            Write-Verbose "Setting Annotation Configuration"
            $annotationObject.id = $annotationId
            $setAnnotationResult = Set-CluedInAnnotation -Id $annotationObject.id -Object $annotationObject
            Check-ImportResult -Result $setAnnotationResult

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
                        Check-ImportResult -Result $dataSetMappingResult
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
                        Check-ImportResult -Result $dataSetMappingResult
                    }
                }
            }

            Write-Verbose "Setting Annotation Entity Codes"
            $entities = $annotationObject.annotationProperties | Where-Object { $_.useAsEntityCode }
            foreach ($entity in $entities) {
                $setAnnotationEntityCodesResult = Set-CluedInAnnotationEntityCodes -Object $entity -Id $annotationObject.id
                Check-ImportResult -Result $setAnnotationEntityCodesResult
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
            #     Check-ImportResult -Result $edgeResult
            # }
        }
        catch {
            Write-Verbose "Annotation file '$annotationPath' not found or error occured during run"
            Write-Debug $_
            continue
        }

        Write-Host "Updating PreProcess DataSet Rules for $($dataSetObject.name)" -ForegroundColor 'Cyan'
        $preProcessRulesPath = Join-Path -Path $dataSetsPath -ChildPath ('{0}-Preprocess-dataset-rules.json' -f $dataSetObject.id)
        if (!(Test-Path -Path $preProcessRulesPath -PathType 'Leaf')) { Write-Warning "No pre process rules to import"; continue}

        $preProcessRulesJson = Get-Content -Path $preProcessRulesPath | ConvertFrom-Json -Depth 20
        $preProcessRulesObject = $preProcessRulesJson.data.preparation.getAllPreProcessDataSetRules

        foreach($preProcessingRule in $preProcessRulesObject.data){
            $annotationId = ($lookupAnnotations | Where-Object { $_.OriginalAnnotationId -eq $preProcessingRule.annotationId }).AnnotationId
            if($null -eq $annotationId){
                Write-Warning "Could not find the new annotation id to assign to the pre processing rule. PreProcessingRuleId: $($preProcessingRule.id); Original Annotation Id: $($preProcessingRule.annotationId);"
            }

            $existingPreProcessRuleObjects = (Get-CluedPreProcessDataSetRules -Id $annotationId).data.preparation.getAllPreProcessDataSetRules.data
            $existingPreProcessingRule = $existingPreProcessRuleObjects | Where-Object { $_.displayName -eq $preProcessingRule.displayName }
            # If Exists Update
            if($null -ne $existingPreProcessingRule){
                Write-Host "Updating PreProcessingRule: $($preProcessingRule.displayname)" -ForegroundColor 'Cyan'
                $setPreProcessRuleResult = Set-CluedInPreProcessDataSetRule -Id $existingPreProcessingRule.Id -Configuration $preProcessingRule
                Check-ImportResult -Result $setCluedInPrProcessRuleResult
            } else {
                # Create
                Write-Host "Creating PreProcessingRule: $($preProcessingRule.displayname)" -ForegroundColor 'Cyan'
                $newPreProcessRuleResults = New-CluedInPreProcessDataSetRule -AnnotationId $annotationId -Configuration $preProcessingRule
                Check-ImportResult -Result $newPreProcessRuleResults
            }
        }
    }
}
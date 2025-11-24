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

    if ($dataSets.count -eq 0) { return }

    $vocabulariesKeys = Get-CluedInVocabularyKey -All
    $vocabulariesKeysObject = $vocabulariesKeys.data.management.vocabularyKeys.data

    foreach ($dataSet in $dataSets) {
        $dataSetJson = Get-Content -Path $dataSet.FullName | ConvertFrom-Json -Depth 20
        $dataSetObject = $dataSetJson.data.inbound.dataSet
        Write-Host "Processing Data Set: $($dataSetObject.name) ($($dataSetObject.id))" -ForegroundColor 'Cyan'

        if ($dataSetObject.dataSource.type -eq 'file') {
            Write-Warning "Importing of 'file' type data sets are not supported. Only endpoints and databases are. Skipping import."
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
            
            if($dataSetObject.dataSource.type -eq "endpoint"){
                # Force autoSubmit to false as we don't want it to process automatically when transferred
                $dataSetObject.configuration.object.autoSubmit = $false
            }

            Write-Host "Creating '$($dataSetObject.name)' as it doesn't exist" -ForegroundColor 'DarkCyan'
            $dataSetResult = New-CluedInDataSet -Object $dataSetObject
            Check-ImportResult -Result $dataSetResult
            $dataSetId = $dataSetResult.data.inbound.createDataSets.id

            if ($dataSetObject.dataSource.type -eq 'endpoint') {
                $endpoint = '{0}/upload/api/endpoint/{1}' -f ${env:CLUEDIN_ENDPOINT}, $dataSetId
                Write-Host "New Endpoint created: $endPoint"
            }

            # Update data set configuration
            Set-CluedInDataSetConfig -Id $dataSetId -OnlyUpdateClueHeadVersion $dataSetObject.onlyUpdateClueHeadVersion 

        } else {
            $dataSourceObject = (Get-CluedInDataSource -Search $dataSetObject.dataSource.name).data.inbound.dataSource
            $destinationDataSetObject = $dataSourceObject.dataSets | Where-Object { $_.name -eq $dataSetObject.name }
            $dataSetId = $destinationDataSetObject.id

            if (!$dataSetId) { Write-Error "Issue getting dataSetId so could not update existing dataset configuration"; continue }

            # Update data set configuration
            Set-CluedInDataSetConfig -Id $dataSetId -OnlyUpdateClueHeadVersion $dataSetObject.onlyUpdateClueHeadVersion 
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

            $currentFieldMappings = (Get-CluedInDataSet -Id $dataSetId).data.inbound.dataSet.fieldMappings
            foreach ($mapping in $dataSetObject.fieldMappings) {
                Write-Host "Processing field mapping: $($mapping.originalField)" -ForegroundColor 'Cyan'
                
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
                        $fieldVocabKeyObject = $vocabulariesKeysObject | Where-Object { $_.key -eq $mapping.key } 
                        if (!$fieldVocabKeyObject.vocabularyKeyId) {
                            Write-Warning "Key: $($mapping.key) doesn't exist. Mapping will be skipped for '$($mapping.originalField)'"
                            continue
                        }
                        try {
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
                                    useAsEntityCode = $false
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
                        }
                        catch {
                            Write-Warning "Error setting dataset mapping: $_"
                            continue
                        }
                        Check-ImportResult -Result $dataSetMappingResult
                    }
                }
            }

            Write-Host "Processing Edges" -ForegroundColor 'Cyan'
            $edges = $annotationObject.annotationProperties | Where-Object {$_.annotationEdges}
            $cuedInAnnotation = Get-CluedInAnnotations -id $annotationId
            
            if($null -eq $cuedInAnnotation){
                Write-Warning "Could not find the annotation with id $annotationId. Skipping edges"
            }else{
                foreach ($edge in $edges) {
                    foreach ($edgeMapping in $edge.annotationEdges) {
                        # Skip if strict edge as we cannot guarentee we find the correct dataset/source/group
                        if($null -ne $edgeMapping.DataSetId -or $null -ne $edgeMapping.DataSourceGroupId -or $null -ne $edgeMapping.DataSourceId) {
                            Write-Warning "Importing of Strict Edges are not supported. Skipping strict edge for $($edgeMapping.key)"
                            continue
                        }
                        # Check if any object inside annotationEdges matches all values in edgeMapping (excluding id and dataSetId), regardless of extra properties in the candidate
                        $existingEdge = $false

                        # 1. Choose the properties you want to IGNORE.
                        $ignore = 'id', 'dataSetId'

                        # 2. Build a once-off JSON string for the reference object (minus the ignored props).
                        $refJson =$refJson = Remove-NestedProperties ($edgeMapping | Select-Object -ExcludeProperty $ignore) | ConvertTo-Json -Depth 20 -Compress

                        # 3. Walk the array and compare each element.
                        foreach ($edge in $cuedInAnnotation.data.preparation.annotation.annotationProperties.annotationEdges) {
                            $edgeJson = Remove-NestedProperties ($edge | Select-Object -ExcludeProperty $ignore) | ConvertTo-Json -Depth 20 -Compress
                            if ($edgeJson -eq $refJson) {
                                $existingEdge = $true
                            }
                        }

                        if ($existingEdge) {
                            Write-Warning "Edge $($edgeMapping.edgeType) for $($edgeMapping.key) already exists. Skipping creation."
                            continue
                        }

                        # Resolve edge property mappings     
                        if($edgeMapping.edgeProperties.count -ne 0){
                            $edgeVocabularyObject = $vocabulariesKeysObject | Where-Object { $_.key -eq $edgeMapping.edgeProperties.vocabularyKey.key }
                            if (!$fieldVocabKeyObject.vocabularyKeyId) {
                                Write-Warning "Coule not resolve the vocabulary key $($edgeMapping.edgeProperties.vocabularyKey.key) when trying to add the edge properties. It most likely doesn't exist. Edge creation will be skipped for $($edgeMapping.key)"
                                continue
                            }
                            $edgeMapping.edgeProperties.vocabularyKey.vocabularyKeyId = $edgeVocabularyObject.vocabularyKeyId
                            $edgeMapping.edgeProperties.vocabularyKey.vocabularyId = $edgeVocabularyObject.vocabularyId
                        }

                        # Create the edge mapping
                        Write-Host "Creating edge $($edgeMapping.edgeType) for $($annotationObject.name)" -ForegroundColor 'Cyan'
                        $edgeResult = New-CluedInEdgeMapping -Object $edgeMapping -AnnotationId $annotationId
                        Check-ImportResult -Result $edgeResult
                    }
                }
            }
        }
        catch {
            Write-Error "Annotation file '$annotationPath' not found or error occured during run"
            Write-Host $_
            continue
        }

        Write-Host "Updating Identifiers for $($dataSetObject.name)" -ForegroundColor 'Cyan'
        $annotationCodesPath = Join-Path -Path $dataSetsPath -ChildPath ('{0}-Annotation-Codes.json' -f $dataSetObject.id)
        if (!(Test-Path -Path $annotationCodesPath -PathType 'Leaf')) { Write-Information "No codes to import"; continue}

        $annotationCodesJson = Get-Content -Path $annotationCodesPath | ConvertFrom-Json -Depth 20
        $annotationCodesObject = $annotationCodesJson.data.preparation.getAnnotationCodes

        foreach($annotationCode in $annotationCodesObject){
            $annotationId = ($lookupAnnotations | Where-Object { $_.OriginalAnnotationId -eq $annotationCode.annotationId }).AnnotationId
            if($null -eq $annotationId){
                Write-Warning "Could not find the new annotation id to assign to the identifier. AnnotationCodeId: $($annotationCode.id); Original Annotation Id: $($annotationCode.annotationId);"
            }

            $existingAnnotationCodeObjects = (Get-CluedInAnnotationCodes -Id $annotationId).data.preparation.getAnnotationCodes
            $existingAnnotationCode = $existingAnnotationCodeObjects | Where-Object { $_.vocabKey -eq $annotationCode.vocabKey }

            if($existingAnnotationCode.count -gt 1){
                Write-Warning "Multiple existing annotation codes found for VocabKey: $($annotationCode.vocabKey). Properties are Type: $($annotationCode.type), EntityCodeOrigin: $($annotationCode.entityCodeOrigin). Skipping import of this identifier."
                continue
            }

            # If Exists Update
            if($null -ne $existingAnnotationCode){
                Write-Host "Updating Identifier: $($existingAnnotationCode.vocabKey) $($existingAnnotationCode.entityCodeOrigin)" -ForegroundColor 'Cyan'
                $setAnnotationCodeResult = Set-CluedInAnnotationCode -Id $existingAnnotationCode.id -Configuration $annotationCode
                Check-ImportResult -Result $setAnnotationCodeResult
            } else {
                # Create
                Write-Host "Creating Identifier: $($annotationCode.vocabKey) $($annotationCode.entityCodeOrigin)" -ForegroundColor 'Cyan'
                $newAnnotationCodeResults = New-CluedInAnnotationCode -AnnotationId $annotationId -Configuration $annotationCode
                Check-ImportResult -Result $newAnnotationCodeResults
            }
        }

        Write-Host "Updating PreProcess DataSet Rules for $($dataSetObject.name)" -ForegroundColor 'Cyan'
        $preProcessRulesPath = Join-Path -Path $dataSetsPath -ChildPath ('{0}-Preprocess-dataset-rules.json' -f $dataSetObject.id)
        if (!(Test-Path -Path $preProcessRulesPath -PathType 'Leaf')) { Write-Information "No pre process rules to import"; continue}

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
                $setPreProcessRuleResult = Set-CluedInPreProcessDataSetRule -Id $existingPreProcessingRule.id -Configuration $preProcessingRule
                Check-ImportResult -Result $setPreProcessRuleResult
            } else {
                # Create
                Write-Host "Creating PreProcessingRule: $($preProcessingRule.displayname)" -ForegroundColor 'Cyan'
                $newPreProcessRuleResults = New-CluedInPreProcessDataSetRule -AnnotationId $annotationId -Configuration $preProcessingRule
                Check-ImportResult -Result $newPreProcessRuleResults
            }
        }
    }
}

function Set-CluedInDataSetConfig {
    param (
        [Parameter(Mandatory)]
        [guid]$Id,

        [Parameter(Mandatory)]
        [bool]$OnlyUpdateClueHeadVersion
    )

    # Check and ensure onlyUpdateClueHeadVersion is set
    $updateParams = @{
        Id = $Id
        onlyUpdateClueHeadVersion = $OnlyUpdateClueHeadVersion
    }

    try {
        Write-Host "Updating Data Set configuration for: $($DataSetObject.name)" -ForegroundColor 'Cyan'
        $updateResult = Set-CluedInDataSet @updateParams
        Check-ImportResult -Result $updateResult
    } catch {
        Write-Warning "Failed to update dataset configuration for $($DataSetObject.name)"
        Write-Debug $_
    }
}

function Remove-NestedProperties {
    param($edgeMapping)
    $copy = $edgeMapping | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    if ($copy.edgeProperties) {
        foreach ($prop in $copy.edgeProperties) {
            $prop.PSObject.Properties.Remove('id')
            $prop.PSObject.Properties.Remove('annotationEdgeId')
            if ($prop.vocabularyKey) {
                $prop.vocabularyKey.PSObject.Properties.Remove('vocabularyId')
                $prop.vocabularyKey.PSObject.Properties.Remove('vocabularyKeyId')
            }
        }
    }
    return $copy
}
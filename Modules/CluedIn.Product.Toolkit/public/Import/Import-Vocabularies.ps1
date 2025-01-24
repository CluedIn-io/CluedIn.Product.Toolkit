function Import-Vocabularies{
    <#
        .SYNOPSIS
        Imports deduplication projects

        .DESCRIPTION
        Imports deduplication projects

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-Vocabularies -RestorePath "c:\backuplocation"

        This will import all of the export targets
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )
    
    Write-Host "INFO: Importing Vocabularies" -ForegroundColor 'Green'

    $vocabPath = Join-Path -Path $RestorePath -ChildPath 'DataCatalog/Vocab'

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

    return $lookupVocabularies
}
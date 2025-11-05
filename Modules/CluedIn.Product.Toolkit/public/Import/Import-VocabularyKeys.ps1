function Import-VocabularyKeys{
    <#
        .SYNOPSIS
        Imports deduplication projects

        .DESCRIPTION
        Imports deduplication projects

        .PARAMETER RestorePath
        This is the location of the export files

        .PARAMETER LookupVocabularies
        A list that maps original vocabulary ids to the newly created ones in the system

        .PARAMETER LookupGlossaryTerms
        A list that maps original glossary term ids to the newly created ones in the system

        .EXAMPLE
        PS> Import-VocabularyKeys -RestorePath "c:\backuplocation"

        This will import all of the export targets
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath,
        [Parameter(Mandatory)][Object]$LookupVocabularies,
        [Parameter(Mandatory)][Object]$LookupGlossaryTerms
    )
    
    Write-Host "INFO: Importing Vocabulary Keys" -ForegroundColor 'Green'

    $vocabKeysPath = Join-Path -Path $RestorePath -ChildPath 'DataCatalog/Keys'

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

            $currentVocabularyKeyObjectResult = Get-CluedInVocabularyKey -KeyName $key.key
            $currentVocabularyKeyObject = $currentVocabularyKeyObjectResult.data.management.vocabularyPerKey
            
            if ($key.mapsToOtherKeyId) {
                $mappedKeyId = Get-CluedInVocabularyKey -KeyName $key.mappedKey.key
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
                
                ResolveLookupKeys $key $LookupGlossaryTerms

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

                ResolveLookupKeys $key $LookupGlossaryTerms

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
}

function ResolveLookupKeys ($key, $LookupGlossaryTerms) {
    if($key.dataType -eq "Lookup"){
        if($null -eq $key.glossaryTermId){
            Write-Warning "Lookup vocabulary key does not have a glossary term assigned. Vocabulary: '$vocabName'; Vocabulary Key: '$($key.name)';"
        } else {
            Write-Host "Resolving Lookup Glossary Term"  -ForegroundColor 'DarkCyan'

            if($null -eq $LookupGlossaryTerms -or $LookupGlossaryTerms.Count -eq 0){
                Write-Warning "No Lookup Glossary Terms provided. Most likey due to no Glossary Terms not being imported. Please make sure you export and import required glossaries if you are importing lookup keys."
            }

            $glossaryTermId = ($LookupGlossaryTerms | Where-Object { $_.OriginalGlossaryTermId -eq $key.glossaryTermId })?.GlossaryTermId

            if([string]::IsNullOrWhiteSpace($glossaryTermId))
            {
                Write-Warning "Can not find matching glossary term for the look up field. Vocabulary: '$vocabName'; Vocabulary Key: '$($key.name)'; OriginalTermId: '$($key.glossaryTermId)'"
                continue
            }
            Write-Host "Updating lookup glossary term id. Vocabulary: '$vocabName'; Vocabulary Key: '$($key.name)'; NewGlossaryTermId: '$glossaryTermId'; OriginalGlossaryTermId: '$($key.glossaryTermId)'"  -ForegroundColor 'DarkCyan'
            $key.glossaryTermId = $glossaryTermId
        }
    }
}
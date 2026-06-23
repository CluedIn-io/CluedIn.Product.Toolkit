function Export-VocabularyKeys {
    <#
        .SYNOPSIS
        Exports individual vocabulary keys by key name.

        .DESCRIPTION
        Exports a specified set of vocabulary keys by their full key name (e.g. 'organization.user.firstName').
        Keys are saved in the same structure as Export-Vocabularies so that Import-VocabularyKeys can process them
        without any additional steps.

        Unlike Export-Vocabularies, this function targets individual keys rather than exporting every key
        that belongs to a vocabulary.

        .PARAMETER BackupPath
        The path to the backup folder.

        .PARAMETER SelectVocabularyKeys
        A comma-separated list of full vocabulary key names to export.

        Example: 'organization.user.firstName, organization.user.lastName'

        .EXAMPLE
        PS> Export-VocabularyKeys -BackupPath "c:\backuplocation" -SelectVocabularyKeys 'organization.user.firstName, organization.user.lastName'

        Exports the two specified vocabulary keys.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectVocabularyKeys = 'None'
    )

    if ($SelectVocabularyKeys -eq 'None') { return }

    $dataCatalogPath = Join-Path -Path $BackupPath -ChildPath 'DataCatalog'
    $vocabKeysPath = Join-Path -Path $dataCatalogPath -ChildPath 'Keys'
    if (!(Test-Path -Path $vocabKeysPath -PathType Container)) { New-Item $vocabKeysPath -ItemType Directory | Out-Null }

    Write-Host "INFO: Exporting individual Vocabulary Keys" -ForegroundColor 'Green'

    $collectedKeys = @()
    $keyIdentifiers = ($SelectVocabularyKeys -Split ',').Trim()

    foreach ($keyName in $keyIdentifiers) {
        $result = Get-CluedInVocabularyKey -KeyName $keyName
        $key = $result.data.management.vocabularyPerKey

        if (!$key -or !$key.key) {
            Write-Warning "Vocabulary Key '$keyName' was not found. This won't be backed up"
            continue
        }

        Write-Host "Found Vocabulary Key: '$($key.displayName)' ($($key.vocabularyKeyId))" -ForegroundColor 'Cyan'
        $collectedKeys += $key
    }

    # Group collected keys by their parent vocabularyId so that one file is written per vocabulary,
    # matching the structure produced by Export-Vocabularies.
    $vocabPath = Join-Path -Path $dataCatalogPath -ChildPath 'Vocab'
    if (!(Test-Path -Path $vocabPath -PathType Container)) { New-Item $vocabPath -ItemType Directory | Out-Null }

    $groupedKeys = $collectedKeys | Group-Object -Property vocabularyId

    foreach ($group in $groupedKeys) {
        $vocabId = $group.Name
        $outputFile = Join-Path -Path $vocabKeysPath -ChildPath "$vocabId.json"
        $newKeys = @($group.Group)

        # Export parent vocabulary metadata if not already present (required by Import-Vocabularies
        # to build the lookup table that Import-VocabularyKeys depends on).
        $vocabFile = Join-Path -Path $vocabPath -ChildPath "$vocabId.json"
        if (!(Test-Path $vocabFile)) {
            $vocab = Get-CluedInVocabularyById -Id $vocabId
            if ((!$?) -or ($vocab.errors)) {
                Write-Warning "Could not retrieve vocabulary metadata for '$vocabId'. Keys may not import correctly without it."
            }
            else {
                Write-Host "Exporting Vocabulary metadata: '$($vocab.data.management.vocabulary.vocabularyName)' ($vocabId)" -ForegroundColor 'Cyan'
                $vocab | Out-JsonFile -Path $vocabPath -Name $vocabId
            }
        }

        $keyNames = ($newKeys.ForEach({ '[{0}]' -f $_.displayName })) -join ', '

        if (Test-Path $outputFile) {
            # File already exists (e.g. written by Export-Vocabularies). Merge without duplicates.
            $existing = Get-Content $outputFile -Raw | ConvertFrom-Json -Depth 20
            $existingKeys = @($existing.data.management.vocabularyKeysFromVocabularyId.data)

            foreach ($key in $newKeys) {
                if ($existingKeys.vocabularyKeyId -notcontains $key.vocabularyKeyId) {
                    $existingKeys += $key
                }
            }

            $existing.data.management.vocabularyKeysFromVocabularyId.data = $existingKeys
            $existing.data.management.vocabularyKeysFromVocabularyId.total = $existingKeys.Count
            $existing | ConvertTo-Json -Depth 20 | Out-File -FilePath $outputFile -Encoding UTF8

            Write-Host "Merged Keys into '$vocabId': $keyNames" -ForegroundColor 'Cyan'
        }
        else {
            # Build the same wrapper structure as getVocabularyKeysFromVocabularyId returns.
            $structure = [PSCustomObject]@{
                data = [PSCustomObject]@{
                    management = [PSCustomObject]@{
                        id              = "management" # Copied this value to reflect the structure returned by the API. It shouldnt matter but aligning it just incase something uses it downstream 
                        vocabularyKeysFromVocabularyId = [PSCustomObject]@{
                            total      = $newKeys.Count
                            data       = $newKeys
                            __typename = 'PagedVocabularyKey'
                        }
                        __typename = 'Management'
                    }
                }
            }

            Write-Host "Exporting Keys for Vocabulary '$vocabId': $keyNames" -ForegroundColor 'Cyan'
            $structure | Out-JsonFile -Path $vocabKeysPath -Name $vocabId
        }
    }
}

function Export-Vocabularies{
    <#
        .SYNOPSIS
        Wrapper for exporting data source sets

        .DESCRIPTION
        Wrapper for exporting data source sets

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER SelectVocabularies
        Specifies what Vocabularies to export. It supports Used, All, None, and csv format of the Id's

        'Used' exports every custom vocabulary that CluedIn reports as being in use. The core vocabularies
        that ship with the product are always excluded, which is what makes this a usable alternative to
        'All' (which isn't supported as it would pull in thousands of core keys).

        .EXAMPLE
        PS> Export-Vocabularies -BackupPath "c:\backuplocation"

        This will export all of the data source sets details

        .EXAMPLE
        PS> Export-Vocabularies -BackupPath "c:\backuplocation" -SelectVocabularies 'Used'

        This will export every custom vocabulary that is in use, along with their keys
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectVocabularies = 'None'
    )
    # Vocabulary
    $dataCatalogPath = Join-Path -Path $BackupPath -ChildPath 'DataCatalog'
    $vocabPath = Join-Path -Path $dataCatalogPath -ChildPath 'Vocab'
    if (!(Test-Path -Path $vocabPath -PathType Container)) { New-Item $vocabPath -ItemType Directory | Out-Null }

    $vocabKeysPath = Join-Path -Path $dataCatalogPath -ChildPath 'Keys'
    if (!(Test-Path -Path $vocabKeysPath -PathType Container)) { New-Item $vocabKeysPath -ItemType Directory | Out-Null }

    if ($SelectVocabularies -ne 'None') {
        $vocabularies = Get-CluedInVocabulary -IncludeCore
        Write-Host "INFO: Exporting Vocabularies and Keys" -ForegroundColor 'Green'
    }

    $vocabularyIds = switch ($SelectVocabularies) {
        'All' {
            $null # All not supported at the moment
            #($vocabularies.data.management.vocabularies.data | Where-Object {$_.isCluedInCore -eq $False}).vocabularyId
        }
        'Used' {
            # Core vocabularies are filtered out by Get-CluedInVocabulary, so this stays to the custom ones.
            $usedVocabularies = Get-CluedInVocabulary -Used
            [array]$usedVocabularyIds = $usedVocabularies.data.management.vocabularies.data.vocabularyId
            if (!$usedVocabularyIds) { Write-Warning "No vocabularies are reported as used. Nothing will be backed up" }
            $usedVocabularyIds
        }
        'None' { $null }
        default { ($SelectVocabularies -Split ',').Trim() }
    }

    foreach ($id in $vocabularyIds) {
        # Vocab
        if(Test-IsGuid $id)
        {
            $vocab = Get-CluedInVocabularyById -Id $id

            if ((!$?) -or ($vocab.errors)) {    
                Write-Warning "Id '$id' was not found. This won't be backed up"; 
                continue 
            }
        } else {
            $found = $false
            foreach($vocabulary in $vocabularies.data.management.vocabularies.data) {
                if(($vocabulary.keyPrefix -eq $id) -and ($vocabulary.isCluedInCore -eq $False))
                {
                    $vocab = Get-CluedInVocabularyById -Id $vocabulary.vocabularyId
                    $id = $vocabulary.vocabularyId
                    $found = $true

                    Write-Verbose "$($vocabulary.keyPrefix) maps to $($vocabulary.vocabularyName)"
                    break
                }
            }

            if($found -eq $false)
            {   
                Write-Warning "Vocabulary '$id' was not found. This won't be backed up"; 
                continue 
            }
        }
        

        Write-Host "Exporting Vocabulary: '$($vocab.data.management.vocabulary.vocabularyName) ($id)'" -ForegroundColor 'Cyan'
        $vocab | Out-JsonFile -Path $vocabPath -Name $id

        # Keys
        $vocabKey = Get-CluedInVocabularyKey -Id $id
        if ((!$?) -or ($vocabKey.errors)) { Write-Warning "Id '$id' was not found. This won't be backed up"; continue }

        $keys = $vocabKey.data.management.vocabularyKeysFromVocabularyId.data.displayName
        $keys = ($keys.ForEach({'[{0}]' -f $_})) -Join ', '
        Write-Host "Exporting Keys: $keys" -ForegroundColor 'Cyan'
        $vocabKey | Out-JsonFile -Path $vocabKeysPath -Name $id
    }
}
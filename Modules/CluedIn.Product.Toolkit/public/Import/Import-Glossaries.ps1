function Import-Glossaries{
    <#
        .SYNOPSIS
        Imports deduplication projects

        .DESCRIPTION
        Imports deduplication projects

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-Glossaries -RestorePath "c:\backuplocation"

        This will import all of the glossaries
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )

    Write-Host "INFO: Importing Glossaries" -ForegroundColor 'Green'

    $glossariesPath = Join-Path -Path $RestorePath -ChildPath 'Glossaries'

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

    return $lookupGlossaryTerms
}
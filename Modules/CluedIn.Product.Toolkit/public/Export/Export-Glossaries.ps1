function Export-Glossaries{
    <#
        .SYNOPSIS
        Wrapper for exporting data source sets

        .DESCRIPTION
        Wrapper for exporting data source sets

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER SelectGlossaries
        Specifies what glossaries to export. It supports All, None, and csv format of the Id's

        .EXAMPLE
        PS> Export-Glossaries -BackupPath "c:\backuplocation"

        This will export all of the data source sets details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectGlossaries = 'None'
    )   
    Write-Host "INFO: Exporting Glossaries" -ForegroundColor 'Green'
    $glossaryPath = Join-Path -Path $BackupPath -ChildPath 'Glossaries'
    if (!(Test-Path -Path $glossaryPath -PathType Container)) { New-Item $glossaryPath -ItemType Directory | Out-Null }

    switch ($SelectGlossaries) {
        'All' {
            $glossaries = Get-CluedInGlossary
            [array]$glossaryIds = $glossaries.data.management.glossaryCategories.id
        }
        'None' { $null }
        default { $glossaryIds = ($SelectGlossaries -Split ',').Trim() }
    }

    foreach ($glossaryId in $glossaryIds) {
        $glossaryExportPath = Join-Path -Path $glossaryPath -ChildPath $glossaryId
        if (!(Test-Path -Path $glossaryExportPath -PathType Container)) { New-Item $glossaryExportPath -ItemType Directory | Out-Null }

        # Glossary
        $glossaryConfig = Get-CluedInGlossary -Id $glossaryId
        if ($glossaryConfig.errors) {
            Write-Warning "Received error '$($glossaryConfig.errors.message)'. Skipping id '$glossaryId'."
            continue
        }
        $glossaryConfig | Out-JsonFile -Path $glossaryExportPath -Name ('{0}-Glossary' -f $glossaryId)

        # Glossary Terms
        $glossaryTerms = Get-CluedInGlossaryTerms -GlossaryId $glossaryId
        $glossaryTermsIds = $glossaryTerms.data.management.glossaryTerms.data.id

        # Glossary Term Configuration
        foreach ($termId in $glossaryTermsIds) {
            $glossaryTermConfig = Get-CluedInGlossaryTerm -Id $termId
            $glossaryTermConfig | Out-JsonFile -Path $glossaryExportPath -Name ('{0}-Term' -f $termId)
        }
    }
}
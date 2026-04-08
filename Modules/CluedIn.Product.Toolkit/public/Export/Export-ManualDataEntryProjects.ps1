function Export-ManualDataEntryProjects{
    <#
        .SYNOPSIS
        Wrapper for exporting manual data entry projects

        .DESCRIPTION
        Wrapper for exporting manual data entry projects

        .PARAMETER BackupPath
        The path to the backup folder

        .EXAMPLE
        PS> Export-DataSets -BackupPath "c:\backuplocation"

        This will export all of the deduplication project details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectManualDataEntryProjects = 'None'
    )
    Write-Host "INFO: Exporting Manual Data Entry Projects" -ForegroundColor 'Green'

    $path = Join-Path -Path $BackupPath -ChildPath 'ManualDataEntryProjects'
    if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }

     switch ($SelectManualDataEntryProjects) {
        'All' {
            $manualDataEntryProjects = Get-CluedInManualDataEntryProjects
            [array]$manualDataEntryProjectIds = $manualDataEntryProjects.data.management.manualDataEntryProjects.data.id
        }
        'None' { $null }
        default { $manualDataEntryProjectIds = ($SelectManualDataEntryProjects -Split ',').Trim() }
    }

    foreach ($id in $manualDataEntryProjectIds) {
        Write-Verbose "Processing id: $id"
        $manualDataEntryProject = Get-CluedInManualDataEntryProject -Id $id
        if ((!$?) -or ($manualDataEntryProject.errors)) { Write-Warning "Manual data entry project '$id' was not found. This won't be backed up"; continue }

        Write-Host "Exporting Manual Data Entry Project: '$($manualDataEntryProject.data.management.manualDataEntryProject.title) ($id)'" -ForegroundColor 'Cyan'
        $manualDataEntryProject | Out-JsonFile -Path $path -Name ('{0}-ManualDataEntryProject' -f $id)

        $annotationId = $manualDataEntryProject.data.management.manualDataEntryProject.annotationId
        switch ($annotationId) {
            $null { Write-Warning "No annotation detected. Skipping export of annotations" }
            default {
                Write-Host "Exporting Annotation" -ForegroundColor 'Cyan'
                Get-CluedInAnnotations -id $annotationId | Out-JsonFile -Path $path -Name ('{0}-Annotation' -f $id)
            }
        }

        # Left for the future when manual data entry switches to using annotation codes
        # switch ($annotationId) {
        #     $null { Write-Warning "No annotation detected. Skipping export of codes" }
        #     default {
        #         Write-Host "Exporting Codes" -ForegroundColor 'Cyan'
        #         Get-CluedInAnnotationCodes -Id $annotationId | Out-JsonFile -Path $path -Name ('{0}-Annotation-Codes' -f $id)
        #     }
        # }
    }
}
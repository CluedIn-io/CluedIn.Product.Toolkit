function Import-CleanProjects{
    <#
        .SYNOPSIS
        Imports deduplication projects

        .DESCRIPTION
        Imports deduplication projects

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-CleanProjects -RestorePath "c:\backuplocation"

        This will import all of the clean projects
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )
    Write-Host "INFO: Importing Clean Projects" -ForegroundColor 'Green'
    
    $cleanProjectsPath = Join-Path -Path $RestorePath -ChildPath 'CleanProjects'

    $cleanProjects = Get-ChildItem -Path $cleanProjectsPath -Filter "*.json" -Recurse
    $currentCleanProjects = Get-CluedInCleanProjects
    $currentCleanProjectsObject = $currentCleanProjects.data.preparation.allCleanProjects.projects

    foreach ($cleanProject in $cleanProjects) {
        $cleanProjectJson = Get-Content -Path $cleanProject.FullName | ConvertFrom-Json -Depth 20
        $cleanProjectObject = $cleanProjectJson.data.preparation.cleanProjectDetail

        Write-Host "Processing Clean Project: $($cleanProjectObject.name)" -ForegroundColor 'Green'
        if ($cleanProjectObject.name -notin $currentCleanProjectsObject.name) {
            Write-Host "Creating Clean Project '$($cleanProjectObject.name)'" -ForegroundColor 'Cyan'
            $cleanProjectResult = New-CluedInCleanProject -Name $cleanProjectObject.name -Object $cleanProjectObject
            Check-ImportResult -Result $cleanProjectResult
            continue # No need to drift check on new creations
        }

        $cleanProjectId = ($currentCleanProjectsObject | Where-Object { $_.name -eq $cleanProjectObject.name }).id
        if ($cleanProjectId.count -ne 1) { Write-Error "Multiple Ids returned"; continue }

        Write-Host "Setting Configuration" -ForegroundColor 'Cyan'
        $setConfigurationResult = Set-CluedInCleanProject -Id $cleanProjectId -Object $cleanProjectObject
        Check-ImportResult -Result $setConfigurationResult

    }
}
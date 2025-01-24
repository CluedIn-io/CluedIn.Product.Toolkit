function Export-CleanProjects{
    <#
        .SYNOPSIS
        Wrapper for exporting data source sets

        .DESCRIPTION
        Wrapper for exporting data source sets

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER SelectCleanProjects
        Specifies what clean projects to export. It supports All, None, and csv format of the Id's

        .EXAMPLE
        PS> Export-CleanProjects -BackupPath "c:\backuplocation"

        This will export all of the data source sets details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectCleanProjects = 'None'
    )   
    
    Write-Host "INFO: Exporting Clean Projects" -ForegroundColor 'Green'
    $cleanProjectsPath = Join-Path -Path $BackupPath -ChildPath 'CleanProjects'
    if (!(Test-Path -Path $cleanProjectsPath -PathType Container)) { New-Item $cleanProjectsPath -ItemType Directory | Out-Null }

    switch ($SelectCleanProjects) {
        'All' {
            $cleanProjects = Get-CluedInCleanProjects
            [array]$cleanProjectsIds = $cleanProjects.data.preparation.allCleanProjects.projects.id
        }
        'None' { $null }
        default { $cleanProjectsIds = ($SelectCleanProjects -Split ',').Trim() }
    }

    foreach ($cleanProjectId in $cleanProjectsIds) {
        $cleanProjectConfig = Get-CluedInCleanProject -Id $cleanProjectId
        $cleanProjectConfig | Out-JsonFile -Path $cleanProjectsPath -Name $cleanProjectId
    }
}
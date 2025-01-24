function Export-DeduplicationProjects{
    <#
        .SYNOPSIS
        Wrapper for exporting deduplicationproject logic

        .DESCRIPTION
        Wrapper for exporting deduplicationproject logic

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER SelectDeduplicationProjects
        Specifies what Deduplication Projects to export. It supports All, None, and csv format of the Id's

        .EXAMPLE
        PS> Export-DeduplicationProjects -BackupPath "c:\backuplocation" -SelectDeduplicationProjects 'All'

        This will export all of the deduplication project details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectDeduplicationProjects = 'None'
    )

    # Deduplication Projects
    Write-Host "INFO: Exporting Deduplication Projects" -ForegroundColor 'Green'
    $deduplicationProjectsPath = Join-Path -Path $BackupPath -ChildPath 'DeduplicationProjects'
    if (!(Test-Path -Path $deduplicationProjectsPath -PathType Container)) { New-Item $deduplicationProjectsPath -ItemType Directory | Out-Null }

    switch ($SelectDeduplicationProjects) {
        'All' {
            $deduplicationProjects = Get-CluedInDeduplicationProjects
            [array]$deduplicationProjectIds = $deduplicationProjects.data.management.deDupProjects.data.id
        }
        'None' { $null }
        default { $deduplicationProjectIds = ($SelectDeduplicationProjects -Split ',').Trim() }
    }

    foreach ($deduplicationProjectId in $deduplicationProjectIds) {
        $deduplicationProjectConfig = Get-CluedInDeduplicationProject -Id $deduplicationProjectId
        $deduplicationProjectConfig | Out-JsonFile -Path $deduplicationProjectsPath -Name ('{0}-DeduplicationProject' -f $deduplicationProjectId)

        $deduplicationProjectMatchingRuleConfig = Get-CluedInDeduplicationMatchingRules -Id $deduplicationProjectId
        $deduplicationProjectMatchingRuleConfig | Out-JsonFile -Path $deduplicationProjectsPath -Name ('{0}-MatchingRules' -f $deduplicationProjectId)
    }
}
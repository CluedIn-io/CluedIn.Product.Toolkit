function Export-ExportTargets{
    <#
        .SYNOPSIS
        Wrapper for exporting data source sets

        .DESCRIPTION
        Wrapper for exporting data source sets

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER SelectExportTargets
        Specifies what Export Targets to export. It supports All, None, and csv format of the Id's

        .EXAMPLE
        PS> Export-ExportTargets -BackupPath "c:\backuplocation"

        This will export all of the data source sets details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectExportTargets = 'None'
    )

    Write-Host "INFO: Exporting Export Targets (Connectors)" -ForegroundColor 'Green'
    $exportTargetsPath = Join-Path -Path $BackupPath -ChildPath 'ExportTargets'
    if (!(Test-Path -Path $exportTargetsPath -PathType Container)) { New-Item $exportTargetsPath -ItemType Directory | Out-Null }

    switch ($SelectExportTargets) {
        'All' {
            $exportTargets = Get-CluedInExportTargets
            [array]$exportTargetsId = $exportTargets.data.inbound.connectorConfigurations.configurations.id
        }
        'None' { $null }
        default { $exportTargetsId = ($SelectExportTargets -Split ',').Trim() }
    }

    foreach ($id in $exportTargetsId) {
        $exportTargetConfig = Get-CluedInExportTarget -Id $id
        $exportTargetConfig | Out-JsonFile -Path $exportTargetsPath -Name $id
    }
}
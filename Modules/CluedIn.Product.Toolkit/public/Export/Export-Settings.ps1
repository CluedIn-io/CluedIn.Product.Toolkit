function Export-Settings{
    <#
        .SYNOPSIS
        Wrapper for exporting data source sets

        .DESCRIPTION
        Wrapper for exporting data source sets

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER BackupAdminSettings
        Set if we should backup admin settings or not

        .EXAMPLE
        PS> Export-Settings -BackupPath "c:\backuplocation"

        This will export all of the data source sets details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [switch]$BackupAdminSettings
    )

    $generalPath = Join-Path -Path $BackupPath -ChildPath 'General'
    if (!(Test-Path -Path $generalPath -PathType Container)) { New-Item $generalPath -ItemType Directory | Out-Null }

    Write-Host "INFO: Exporting Admin Settings" -ForegroundColor 'Green'
    if ($BackupAdminSettings) {
        Get-CluedInAdminSetting | Out-JsonFile -Path $generalPath -Name 'AdminSetting'
    }
}
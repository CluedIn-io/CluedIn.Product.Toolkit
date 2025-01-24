function Export-Streams{
    <#
        .SYNOPSIS
        Wrapper for exporting data source sets

        .DESCRIPTION
        Wrapper for exporting data source sets

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER SelectStreams
        Specifies what streams to export. It supports All, None, and csv format of the Id's

        .EXAMPLE
        PS> Export-Streams -BackupPath "c:\backuplocation"

        This will export all of the data source sets details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectStreams = 'None'
    )   
    Write-Host "INFO: Exporting Streams" -ForegroundColor 'Green'
    $exportStreamsPath = Join-Path -Path $BackupPath -ChildPath 'Streams'
    if (!(Test-Path -Path $exportStreamsPath -PathType Container)) { New-Item $exportStreamsPath -ItemType Directory | Out-Null }

    switch ($SelectStreams) {
        'All' {
            $streams = Get-CluedInStreams
            [array]$streamsId = $streams.data.consume.streams.data.id
        }
        'None' { $null }
        default { $streamsId = ($SelectStreams -Split ',').Trim() }
    }

    foreach ($id in $streamsId) {
        $streamConfig = Get-CluedInStream -Id $id
        if ($streamConfig.errors) {
            Write-Warning "Cannot export StreamId '$id'. This is common if permissions are missing on the export target."
            Write-Error "Error: $($streamConfig.errors.message)"
            continue
        }
        $streamConfig | Out-JsonFile -Path $exportStreamsPath -Name $id
    }
}
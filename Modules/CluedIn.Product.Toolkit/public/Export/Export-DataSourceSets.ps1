function Export-DataSourceSets{
    <#
        .SYNOPSIS
        Wrapper for exporting data source sets

        .DESCRIPTION
        Wrapper for exporting data source sets

        .PARAMETER BackupPath
        The path to the backup folder

        .EXAMPLE
        PS> Export-DataSourceSets -BackupPath "c:\backuplocation"

        This will export all of the data source sets details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectDataSets = 'None'
    )
    $path = Join-Path -Path $BackupPath -ChildPath 'Data/SourceSets'
    if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }

    Write-Host "INFO: Exporting Data Sources and Sets" -ForegroundColor 'Green'

    if($SelectDataSets -eq 'None') {
        return @()
    }
    
    $dataSourceSets = Get-CluedInDataSourceSet
    $dataSourceSets | Out-JsonFile -Path $path -Name 'DataSourceSet'

    return $dataSourceSets
}
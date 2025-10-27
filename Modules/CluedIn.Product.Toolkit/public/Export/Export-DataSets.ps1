function Export-DataSets{
    <#
        .SYNOPSIS
        Wrapper for exporting deduplicationproject logic

        .DESCRIPTION
        Wrapper for exporting deduplicationproject logic

        .PARAMETER BackupPath
        The path to the backup folder

        .EXAMPLE
        PS> Export-DataSets -BackupPath "c:\backuplocation"

        This will export all of the deduplication project details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [Parameter()][PSCustomObject]$DataSourceSets,
        [string]$SelectDataSets = 'None'
    )

    $path = Join-Path -Path $BackupPath -ChildPath 'Data/Sets'
    if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }

    $dataSourcePath = Join-Path -Path $BackupPath -ChildPath 'Data/Sources'
    if (!(Test-Path -Path $dataSourcePath -PathType Container)) { New-Item $dataSourcePath -ItemType Directory | Out-Null }

    $dataSources = $DataSourceSets.data.inbound.dataSourceSets.data.datasources

    $dataSetIds = switch ($SelectDataSets) {
        'All' { $dataSources.dataSets.id }
        'None' { $null }
        default { ($SelectDataSets -Split ',').Trim() }
    }

    $dataSourceBackup = @{}

    foreach ($id in $dataSetIds) {
        Write-Verbose "Processing id: $id"
        $set = Get-CluedInDataSet -id $id
        if ((!$?) -or ($set.errors)) { Write-Warning "Data Set Id '$id' was not found. This won't be backed up"; continue }

        $dataSourceId = $set.data.inbound.dataSet.dataSourceId
        $dataSource = Get-CluedInDataSource -Id $dataSourceId

        if (!($dataSource.data.inbound.dataSource)) { Write-Warning "Data Source Id '$dataSourceId' was not found. This won't be backed up"; continue }

        # Caching of exports to avoid duplicated work.
        if (!$dataSourceBackup[$dataSourceId]) {
            Write-Host "Exporting Data Source Id: $dataSourceId" -ForegroundColor 'Cyan'
            # Remove unwanted properties (guard in case the sql section is missing)
            if ($dataSource.data -and $dataSource.data.inbound -and $dataSource.data.inbound.dataSource -and $dataSource.data.inbound.dataSource.sql) {
                $dataSource.data.inbound.dataSource.sql.password = $null
            }
            $dataSource | Out-JsonFile -Path $dataSourcePath -Name ('{0}-DataSource' -f $dataSourceId)
            $dataSourceBackup[$dataSourceId] = $true
        }

        Write-Host "Exporting Data Set: '$($set.data.inbound.dataSet.name) ($id)'" -ForegroundColor 'Cyan'
        $set | Out-JsonFile -Path $path -Name ('{0}-DataSet' -f $id)

        if ($set.data.inbound.dataSet.dataSource.type -eq 'file') {
            Get-CluedInDataSetContent -id $id | Out-JsonFile -Path $path -Name ('{0}-DataSetContent' -f $id)
        }

        $annotationId = $set.data.inbound.dataSet.annotationId
        switch ($annotationId) {
            $null { Write-Warning "No annotation detected. Skipping export of annotations" }
            default {
                Write-Host "Exporting Annotation" -ForegroundColor 'Cyan'
                Get-CluedInAnnotations -id $annotationId | Out-JsonFile -Path $path -Name ('{0}-Annotation' -f $id)
            }
        }

        switch ($annotationId) {
            $null { Write-Warning "No annotation detected. Skipping export of codes" }
            default {
                Write-Host "Exporting Codes" -ForegroundColor 'Cyan'
                Get-CluedInAnnotationCodes -Id $annotationId | Out-JsonFile -Path $path -Name ('{0}-Annotation-Codes' -f $id)
            }
        }

        switch ($annotationId) {
            $null { Write-Warning "No annotation detected. Skipping export of pre-process data set rules" }
            default {
                Write-Host "Exporting Preprocess data set rules" -ForegroundColor 'Cyan'
                Get-CluedPreProcessDataSetRules -Id $annotationId | Out-JsonFile -Path $path -Name ('{0}-Preprocess-dataset-rules' -f $id)
            }
        }
    }
}
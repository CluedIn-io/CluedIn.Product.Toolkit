function Import-DataSources{
    <#
        .SYNOPSIS
        Imports data sources

        .DESCRIPTION
        Imports data sources

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-DataSources -RestorePath "c:\backuplocation"

        This will import all of the data sources
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )

    $dataSourcesPath = Join-Path -Path $RestorePath -ChildPath 'Data/Sources'

    Write-Host "INFO: Importing Data Sources" -ForegroundColor 'Green'
    $dataSources = Get-ChildItem -Path $dataSourcesPath -Filter "*.json"

    foreach ($dataSource in $dataSources) {
        $dataSourceJson = Get-Content -Path $dataSource.FullName | ConvertFrom-Json -Depth 20
        $dataSourceObject = $dataSourceJson.data.inbound.dataSource
        $dataSourceSetName = $dataSourceObject.dataSourceSet.name

        $dataSourceSet = Get-CluedInDataSourceSet -Search $dataSourceSetName
        $dataSourceSetMatch = $dataSourceSet.data.inbound.dataSourceSets.data |
            Where-Object {$_.name -match "^$dataSourceSetName$"}
        if (!$dataSourceSetMatch) {
            $dataSourceSetResult = New-CluedInDataSourceSet -DisplayName $dataSourceSetName
            Check-ImportResult -Result $dataSourceSetResult
            $dataSourceSetMatch = (Get-CluedInDataSourceSet -Search $dataSourceSetName).data.inbound.dataSourceSets.data |
                Where-Object {$_.name -match "^$dataSourceSetName$"}
        }
        $dataSourceObject.dataSourceSet.id = $dataSourceSetMatch.id

        Write-Host "Processing Data Source: $($dataSourceObject.name); ID: $($dataSourceObject.id)" -ForegroundColor 'Cyan'

        $exists = (Get-CluedInDataSource -Search $dataSourceObject.name).data.inbound.dataSource
        $dataSourceId = $exists.id
        if (!$exists) {
            Write-Host "Creating '$($dataSourceObject.name)' as it doesn't exist" -ForegroundColor 'DarkCyan'
            $dataSourceResult = New-CluedInDataSource -Object $dataSourceObject
            Check-ImportResult -Result $dataSourceResult

            $dataSourceId ??= $dataSourceResult.data.inbound.createDataSource.id

            if($dataSourceObject.type -eq "sql")
            {    
                # We only want to  update the configuration if we are creating the datasource as this is essentially the connection string and we do not want to overwrite it
                Write-Host "Updating Database Configuration for $($dataSourceObject.name)" -ForegroundColor 'Cyan'
                $dataSourceDatabaseConfigResult = Set-CluedInDataSourceDatabaseConfiguration -DataSourceId $dataSourceId -Object $dataSourceObject
    
                Check-ImportResult -Result $dataSourceDatabaseConfigResult
            }
        }
        $dataSourceId = $exists.id ?? $dataSourceResult.data.inbound.createDataSource.id

        Write-Host "Updating Configuration for $($dataSourceObject.name)" -ForegroundColor 'Cyan'
        $dataSourceObject.connectorConfiguration.id = (Get-CluedInDataSource -Search $dataSourceObject.name).data.inbound.dataSource.connectorConfiguration.id
        $dataSourceObject.connectorConfiguration.configuration.DataSourceId = $dataSourceId
        $dataSourceConfigResult = Set-CluedInDataSourceConfiguration -Object $dataSourceObject.connectorConfiguration
        Check-ImportResult -Result $dataSourceConfigResult
    }
}
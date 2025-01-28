function Import-Streams{
    <#
        .SYNOPSIS
        Imports deduplication projects

        .DESCRIPTION
        Imports deduplication projects

        .PARAMETER RestorePath
        This is the location of the export files

        .PARAMETER LookupConnectors
        A list that maps original connector ids to the newly created ones in the system

        .EXAMPLE
        PS> Import-Streams -RestorePath "c:\backuplocation" -LookupConnectors $lookupConnectors

        This will import all of the streams
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath,
        [Parameter(Mandatory)][Object]$LookupConnectors
    )

    Write-Host "INFO: Importing Streams" -ForegroundColor 'Green'

    $streamsPath = Join-Path -Path $RestorePath -ChildPath 'Streams'

    $streams = Get-ChildItem -Path $streamsPath -Filter "*.json" -Recurse
    $existingStreams = (Get-CluedInStreams).data.consume.streams.data

    foreach ($stream in $streams) {
        $streamJson = Get-Content -Path $stream.FullName | ConvertFrom-Json -Depth 20
        if ($streamJson.errors) {
            Write-Warning "The exported stream '$($stream.fullName)' is invalid. Skipping"
            continue
        }
        $streamObject = $streamJson.data.consume.stream

        Write-Host "Processing Stream: $($streamObject.name)" -ForegroundColor 'Cyan'

        $streamExists = $existingStreams | Where-Object { $_.name -eq $streamObject.name }
        switch ($StreamExists.count) {
            '0' {
                Write-Verbose "Creating Stream"
                $newStream = New-CluedInStream -Name $streamObject.name
                $streamId = $newStream.data.consume.createStream.id
                Write-Host "Created new stream $($streamId)" -ForegroundColor 'Cyan'
            }
            '1' {
                Write-Verbose "Stream Exists. Updating"
                $streamId = $streamExists.id
                Write-Host "Using existing stream $($streamId)" -ForegroundColor 'Cyan'
            }
            default { Write-Warning "Too many streams exist with name '$($streamObject.name)'"; continue }
        }

        Write-Verbose "Setting configuration"

        $setResult = Set-CluedInStream -Id $streamId -Object $streamObject
        Check-ImportResult -Result $setResult
    
        $lookupConnectorId = $streamObject.connector.Id
        $connectorId = ($LookupConnectors | Where-Object { $_.OriginalConnectorId -eq $lookupConnectorId }).ConnectorId

        if($connectorId -eq $null)
        {
            $connectorId = $($streamObject.connector.Id)
            Write-Host "INFO: Export target '$($connectorId)' was not imported within this run"
        }
        
        $setStreamExportResult = Set-CluedInStreamExportTarget -Id $streamId -ConnectorProviderDefinitionId $connectorId -Object $streamObject
        Check-ImportResult -Result $setStreamExportResult
    }
}
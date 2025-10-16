function Import-ExportTargets{
    <#
        .SYNOPSIS
        Imports deduplication projects

        .DESCRIPTION
        Imports deduplication projects

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-ExportTargets -RestorePath "c:\backuplocation"

        This will import all of the export targets
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )
    
    Write-Host "INFO: Importing Export Targets" -ForegroundColor 'Green'

    $exportTargetsPath = Join-Path -Path $RestorePath -ChildPath 'ExportTargets'

    $exportTargets = Get-ChildItem -Path $exportTargetsPath -Filter "*.json" -Recurse
    $installedExportTargets = (Get-CluedInInstalledExportTargets).data.inbound.connectors

    $cleanProperties = @(
        'connectinString', 'connectionString', 'password'
        'AccountKey', 'authorization'
    )

    $lookupConnectors = @()

    $currentExportTargets = (Get-CluedInExportTargets).data.inbound.connectorConfigurations.configurations
    $targetExists = $targetObject.accountId -in $currentExportTargets.accountId

    $allUsers = (Get-CluedInUsers).data.administration.users # Caching for use down below

    foreach ($target in $exportTargets) {
        $targetJson = Get-Content -Path $target.FullName | ConvertFrom-Json -Depth 20
        $targetObject = $targetJson.data.inbound.connectorConfiguration
        $targetProperties = ($targetObject.helperConfiguration | Get-Member -MemberType 'NoteProperty').Name
        $originalConnectorId = $targetObject.id

        Write-Host "Processing Export Target: $($targetObject.accountDisplay)" -ForegroundColor 'Cyan'
        if (!$targetObject.accountId) {
            $targetObject.accountId = '0'
        }

        $cleanProperties.ForEach({
            if ($_ -in $targetProperties) { $targetObject.helperConfiguration.$_ = $null }
        })
        
        $hasTarget = $false
        $id = $null;

        if($null -ne $currentExportTargets)
        {
            foreach($exportTarget in $currentExportTargets) {
                $exportTargetDisplayName = $exportTarget.accountDisplay.Trim()
                $targetDisplayName = "$($targetObject.helperConfiguration.accountName) $($targetObject.helperConfiguration.fileSystemName) $($targetObject.helperConfiguration.directoryName)"

                if(($targetObject.accountId -eq $currentExportTargets.accountId) -and ($null -ne $targetObject.accountId) -and ('' -ne $targetObject.accountId) -and ('0' -ne $targetObject.accountId))
                {
                    Write-Verbose "Found match on account id :: $($exportTarget.accountDisplay) == $($targetObject.accountDisplay)"
                    $hasTarget = $true
                    $id = $exportTarget.id
                    break
                }
                elseif(($exportTarget.accountDisplay -eq $targetObject.accountDisplay) -and ($exportTarget.providerId -eq $targetObject.providerId))
                {
                    Write-Verbose "Found match on display name :: $($exportTarget.accountDisplay) == $($targetObject.accountDisplay)"
                    $hasTarget = $true
                    $id = $exportTarget.id
                    break
                }
                elseif(($exportTargetDisplayName -eq $targetDisplayName) -and ($exportTarget.providerId -eq $targetObject.providerId))
                {
                    Write-Verbose "Found match on assumed display name :: $($exportTarget.accountDisplay) == $($targetObject.helperConfiguration.accountName) $($targetObject.helperConfiguration.fileSystemName) $($targetObject.helperConfiguration.directoryName)"
                    $hasTarget = $true
                    $id = $exportTarget.id
                    break
                }
            }
        }

        if ($hasTarget -eq $false) {
            if ($targetObject.providerId -notin $installedExportTargets.id) {
                Write-Warning "Export Target '$($targetObject.connector.name)' could not be found. Skipping creation."
                Write-Warning "Please install connector and try again"
                continue
            }
            
            Write-Verbose "Creating Export Target $($targetObject.helperConfiguration)"
            # If the accountDisplay is null, we use id instead as the account display
            $accountDisplay = if ($targetObject.accountDisplay) { $targetObject.accountDisplay } else { $targetObject.id }
            $targetResult = New-CluedInExportTarget -ConnectorId $targetObject.providerId -Configuration $targetObject.helperConfiguration -AccountDisplay $accountDisplay

            $id = $targetResult.data.inbound.createConnection.id
            if (!$id) { Write-Warning "Unable to get Id of target. Importing on top of existing export targets can be flakey. Please manually investigate."; continue }
        }
        else {
            Write-Verbose "Updating Export target '$($targetDisplayName)' as it already exists"
            $targetResult = Set-CluedInExportTargetConfiguration -Id $id -AccountDisplay $targetObject.accountDisplay -Configuration $targetObject.helperConfiguration
        }

        Check-ImportResult -Result $targetResult


        $lookupConnectors += [PSCustomObject]@{
            OriginalConnectorId = $originalConnectorId
            ConnectorId = $id
        }
    }

    return $lookupConnectors
}
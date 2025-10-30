function Import-ExportTargets {
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
        $id = $null
        $matchedExportTarget = $null

        if ($null -ne $currentExportTargets) {
            foreach ($exportTarget in $currentExportTargets) {
                $exportTargetDisplayName = $exportTarget.accountDisplay.Trim()
                $targetDisplayName = "$($targetObject.helperConfiguration.accountName) $($targetObject.helperConfiguration.fileSystemName) $($targetObject.helperConfiguration.directoryName)"

                if (($targetObject.accountId -eq $currentExportTargets.accountId) -and ($null -ne $targetObject.accountId) -and ('' -ne $targetObject.accountId) -and ('0' -ne $targetObject.accountId)) {
                    Write-Verbose "Found match on account id :: $($exportTarget.accountDisplay) == $($targetObject.accountDisplay)"
                    $hasTarget = $true
                    $id = $exportTarget.id
                    $matchedExportTarget = $exportTarget
                    break
                }
                elseif (($exportTarget.accountDisplay -eq $targetObject.accountDisplay) -and ($exportTarget.providerId -eq $targetObject.providerId)) {
                    Write-Verbose "Found match on display name :: $($exportTarget.accountDisplay) == $($targetObject.accountDisplay)"
                    $hasTarget = $true
                    $id = $exportTarget.id
                    $matchedExportTarget = $exportTarget
                    break
                }
                elseif (($exportTargetDisplayName -eq $targetDisplayName) -and ($exportTarget.providerId -eq $targetObject.providerId)) {
                    Write-Verbose "Found match on assumed display name :: $($exportTarget.accountDisplay) == $($targetObject.helperConfiguration.accountName) $($targetObject.helperConfiguration.fileSystemName) $($targetObject.helperConfiguration.directoryName)"
                    $hasTarget = $true
                    $id = $exportTarget.id
                    $matchedExportTarget = $exportTarget
                    break
                }
            }
        }
     
        # If we found an existing export target, restore password fields into the outgoing configuration
        if ($hasTarget -and $matchedExportTarget) {
            $matchedExportTargetConfig = (Get-CluedInExportTarget -Id $matchedExportTarget.id).data.inbound.connectorConfiguration
            Restore-HelperPasswords -TargetObject $targetObject -MatchedExportTarget $matchedExportTargetConfig
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


# Discover names of password fields from connector authMethods (dynamic)
function Get-PasswordPropertyNames {
    param(
        [Parameter(Mandatory)]
        [psobject] $AuthMethods
    )

    $names = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    if ($null -eq $AuthMethods) { return $names }

    foreach ($methodProp in $AuthMethods.PSObject.Properties) {
        $val = $methodProp.Value
        if ($null -eq $val) { continue }

        if ($val -is [System.Collections.IEnumerable] -and -not ($val -is [string])) {
            foreach ($item in $val) {
                if ($item -and ($item.type -eq 'password') -and $item.name) {
                    $null = $names.Add([string]$item.name)
                }
            }
        }
        elseif ($val -is [psobject]) {
            if ($val.type -eq 'password' -and $val.name) {
                $null = $names.Add([string]$val.name)
            }
        }
    }

    return $names
}

# Try to locate authMethods on either targetObject, exportTarget, or by calling a connector fetcher
function Get-ConnectorAuthMethods {
    param(
        [psobject] $ExportTarget
    )

    return $ExportTarget.connector?.authMethods
}

# Merge password values from an existing export target into the targetObject's helperConfiguration
function Restore-HelperPasswords {
    param(
        [Parameter(Mandatory)] [psobject] $TargetObject,
        [Parameter(Mandatory)] [psobject] $MatchedExportTarget
    )

    # Find authMethods -> figure out which fields are 'password'
    $authMethods = Get-ConnectorAuthMethods -ExportTarget $MatchedExportTarget
    if ($null -eq $authMethods) { 
        return 
    }

    $passwordNames = Get-PasswordPropertyNames -AuthMethods $authMethods
    if ($passwordNames.Count -eq 0) { 
        return 
    }

    # Where we copy *to*
    $destHelper = $TargetObject.helperConfiguration
    if ($null -eq $destHelper) {
        # create if absent so downstream cmdlets have a full config
        $TargetObject | Add-Member -NotePropertyName helperConfiguration -NotePropertyValue (@{}) -Force
        $destHelper = $TargetObject.helperConfiguration
    }

    # Some objects use a nested 'helperConfiguration' key inside helperConfiguration (seen in a few exports)
    $nestedDest = $destHelper.helperConfiguration
    if ($null -ne $nestedDest -and -not ($nestedDest -is [hashtable] -or $nestedDest -is [psobject])) {
        $nestedDest = $null # ignore weird types
    }

    # Where we copy *from*
    $sourceHelper = $MatchedExportTarget.helperConfiguration ?? $MatchedExportTarget.connectorConfiguration?.helperConfiguration
    if ($null -eq $sourceHelper) {
        return 
    }

    foreach ($name in $passwordNames) {
        $srcProp = $sourceHelper.PSObject.Properties[$name]
        if ($srcProp -and $null -ne $srcProp.Value -and "$($srcProp.Value)".Length -gt 0) {

            # Only backfill if missing or empty on destination (avoid clobbering explicit values)
            $destHas = $destHelper.PSObject.Properties[$name]
            $needsWrite = $true
            if ($destHas) {
                $needsWrite = ($null -eq $destHas.Value -or "$($destHas.Value)".Length -eq 0)
            }

            if ($needsWrite) {
                $destHelper | Add-Member -NotePropertyName $name -NotePropertyValue $srcProp.Value -Force
            }

            # Also set nested helperConfiguration if it exists and is intended to carry the same keys
            if ($nestedDest) {
                $ndHas = $nestedDest.PSObject.Properties[$name]
                $ndNeedsWrite = $true
                if ($ndHas) {
                    $ndNeedsWrite = ($null -eq $ndHas.Value -or "$($ndHas.Value)".Length -eq 0)
                }
                if ($ndNeedsWrite) {
                    $nestedDest | Add-Member -NotePropertyName $name -NotePropertyValue $srcProp.Value -Force
                    # ensure the nested object is written back
                    $destHelper.helperConfiguration = $nestedDest
                }
            }
        }
    }
}

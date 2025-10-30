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

        # sanitize dynamically based on authMethods
        $exportTargetConfig = Remove-HelperPasswords -Config $exportTargetConfig

        $exportTargetConfig | Out-JsonFile -Path $exportTargetsPath -Name $id
    }
}

# Returns the set of property names whose type == 'password' across all authMethods collections
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

        # authMethods.* entries are typically arrays (e.g., token = [ ... ])
        if ($val -is [System.Collections.IEnumerable] -and -not ($val -is [string])) {
            foreach ($item in $val) {
                if ($item -and ($item.type -eq 'password') -and $item.name) {
                    $null = $names.Add([string]$item.name)
                }
            }
        }
        elseif ($val -is [psobject]) {
            # In case a provider returns an object instead of an array
            if ($val.type -eq 'password' -and $val.name) {
                $null = $names.Add([string]$val.name)
            }
        }
    }

    return $names
}

# Removes any password fields (as discovered from authMethods) from the helperConfiguration object
function Remove-HelperPasswords {
    param(
        [Parameter(Mandatory)]
        [psobject] $Config
    )

    # Walk to the bits we need, defensively
    $cc = $Config.data?.inbound?.connectorConfiguration
    if ($null -eq $cc) { return $Config }

    $authMethods = $cc.connector?.authMethods
    $helper      = $cc.helperConfiguration
    if ($null -eq $authMethods -or $null -eq $helper) { return $Config }

    $passwordNames = Get-PasswordPropertyNames -AuthMethods $authMethods
    if ($passwordNames.Count -eq 0) { return $Config }

    foreach ($name in $passwordNames) {
        $prop = $helper.PSObject.Properties[$name]
        if ($prop) {
            # Remove the property entirely (you could mask instead: $helper.$name = $null or '****')
            $helper.$name = $null
        }
    }

    return $Config
}

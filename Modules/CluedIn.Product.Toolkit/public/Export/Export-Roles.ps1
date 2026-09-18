function Export-Roles{
    <#
        .SYNOPSIS
        Wrapper for exporting roles

        .DESCRIPTION
        Wrapper for exporting roles.

        Each role is exported along with every claim it holds and the access level of that claim.

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER SelectRoles
        Specifies what Roles to export. It supports All, None, and csv format of the names or Id's

        .EXAMPLE
        PS> Export-Roles -BackupPath "c:\backuplocation" -SelectRoles 'All'

        This will export all of the roles along with their claims
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectRoles = 'None'
    )
    Write-Host "INFO: Exporting Roles" -ForegroundColor 'Green'

    $rolesPath = Join-Path -Path $BackupPath -ChildPath 'Roles'
    if (!(Test-Path -Path $rolesPath -PathType Container)) { New-Item $rolesPath -ItemType Directory | Out-Null }

    if ($SelectRoles -ne 'None') {
        $roles = Get-CluedInRoles
        [array]$roleList = $roles.data.administration.roles.data
        if (!$roleList) { Write-Warning "No roles were returned. Nothing will be backed up"; return }
    }

    $roleNames = switch ($SelectRoles) {
        'All' { $roleList.name }
        'None' { $null }
        default {
            $selected = @()
            foreach ($entry in ($SelectRoles -Split ',').Trim()) {
                $role = if (Test-IsGuid $entry) {
                    $roleList | Where-Object { $_.id -eq $entry }
                }
                else {
                    $roleList | Where-Object { $_.name -eq $entry }
                }

                if (!$role) { Write-Warning "Role '$entry' was not found. This won't be backed up"; continue }

                Write-Verbose "$entry maps to $($role.name)"
                $selected += $role.name
            }
            $selected
        }
    }

    foreach ($name in $roleNames) {
        Write-Verbose "Processing role: $name"
        # Claims are only returned when a role is queried by name, hence the lookup above.
        $role = Get-CluedInRole -Name $name
        if ((!$?) -or ($role.errors)) { Write-Warning "Role '$name' was not found. This won't be backed up"; continue }

        $roleObject = $role.data.administration.role
        if (!$roleObject) { Write-Warning "Role '$name' returned no configuration. This won't be backed up"; continue }

        Write-Host "Exporting Role: '$($roleObject.name) ($($roleObject.id))'" -ForegroundColor 'Cyan'
        $role | Out-JsonFile -Path $rolesPath -Name $roleObject.id
    }
}

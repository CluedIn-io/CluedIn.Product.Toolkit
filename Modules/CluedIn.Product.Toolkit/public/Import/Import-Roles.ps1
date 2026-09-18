function Import-Roles{
    <#
        .SYNOPSIS
        Imports roles

        .DESCRIPTION
        Imports roles along with the access level of each of their claims.

        Only the roles and their claims are restored. Role membership isn't part of the export, so who
        belongs to a role has to be set on the destination separately.

        Claims are merged over the ones the destination environment defines rather than being written
        blind. A claim held in the backup that the destination doesn't know about is skipped with a
        warning, and a claim the destination has but the backup doesn't keeps its current value.

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-Roles -RestorePath "c:\backuplocation"

        This will import all of the roles along with their claims
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )

    Write-Host "INFO: Importing Roles" -ForegroundColor 'Green'

    $rolesPath = Join-Path -Path $RestorePath -ChildPath 'Roles'
    if (!(Test-Path -Path $rolesPath -PathType Container)) {
        Write-Verbose "No roles folder found in the backup. Skipping"
        return
    }

    $roles = Get-ChildItem -Path $rolesPath -Filter "*.json"
    foreach ($role in $roles) {
        $roleJson = Get-Content -Path $role.FullName | ConvertFrom-Json -Depth 20
        $roleObject = $roleJson.data.administration.role
        if (!$roleObject.name) { Write-Warning "'$($role.Name)' does not contain a role. Skipping"; continue }

        Write-Host "Processing Role: $($roleObject.name)" -ForegroundColor 'Cyan'
        if ($roleObject.name -match '\s') {
            Write-Warning "Role name '$($roleObject.name)' contains whitespace. Users cannot be assigned to it by name"
        }

        $search = Get-CluedInRoles -Search $roleObject.name
        [array]$exists = $search.data.administration.roles.data | Where-Object { $_.name -eq $roleObject.name }
        if ($exists.count -gt 1) {
            Write-Warning "Multiple matches for role '$($roleObject.name)'. Using the first"
            $exists = $exists[0]
        }

        # The claims of the destination are the baseline. A create returns every claim the environment
        # defines at 'None', and an existing role returns what it currently holds.
        if (!$exists) {
            Write-Verbose "Creating role as it does not exist"
            $createResult = New-CluedInRole -Name $roleObject.name -Description $roleObject.description
            Check-ImportResult -Result $createResult

            $createdRole = $createResult.data.administration.createRole
            if (!$createdRole) { Write-Warning "Role '$($roleObject.name)' was not created. Claims won't be set"; continue }

            $roleId = $createdRole.id
            [array]$currentClaims = $createdRole.claims
        }
        else {
            $roleId = $exists.id
            $current = Get-CluedInRole -Name $roleObject.name
            [array]$currentClaims = $current.data.administration.role.claims
        }

        if (!$currentClaims) { Write-Warning "No claims returned for '$($roleObject.name)'. Claims won't be set"; continue }

        $backupClaims = @{}
        foreach ($claim in $roleObject.claims) {
            if ($claim.name) { $backupClaims[$claim.name] = $claim.value }
        }

        $claims = foreach ($claim in $currentClaims) {
            $value = $backupClaims.ContainsKey($claim.name) ? $backupClaims[$claim.name] : $claim.value
            @{ name = $claim.name; value = $value }
        }

        $unknownClaims = $backupClaims.Keys | Where-Object { $_ -notin $currentClaims.name }
        if ($unknownClaims) {
            Write-Warning "Claims not known to this environment were skipped: $($unknownClaims -Join ', ')"
        }

        Write-Verbose "Setting role claims"
        $setRoleResult = Set-CluedInRole -Id $roleId -Name $roleObject.name -Description $roleObject.description -Claims $claims
        Check-ImportResult -Result $setRoleResult
    }
}

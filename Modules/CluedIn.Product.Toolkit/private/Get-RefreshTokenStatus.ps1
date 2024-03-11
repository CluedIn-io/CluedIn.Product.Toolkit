function Get-ShouldRefreshToken {
    <#
        .DESCRIPTION
        Retruns boolean value as to whether or not to refresh.
        true = refresh required
        false = valid
    #>

    [CmdletBinding()]
    param([string]$JWT)

    $tokenDetails = ($JWT.split('.')[1] | base64 -d 2>nul) | ConvertFrom-Json
    $refreshTime = Get-Date -UnixTimeSeconds $tokenDetails.exp
    Write-Verbose "Refresh Time: $refreshTime"
    return ((Get-Date) -gt $refreshTime)
}
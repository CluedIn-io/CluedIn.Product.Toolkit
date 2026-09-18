function Get-ShouldRefreshToken {
    <#
        .DESCRIPTION
        Retruns boolean value as to whether or not to refresh.
        true = refresh required
        false = valid
    #>

    [CmdletBinding()]
    param([string]$JWT)

    $tokenDetails = ConvertFrom-JWToken -Token $JWT
    $refreshTime = Get-Date -UnixTimeSeconds $tokenDetails.exp
    Write-Verbose "Refresh Time: $refreshTime"
    return ((Get-Date) -gt $refreshTime)
}

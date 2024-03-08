function Get-CluedInAPIToken {
    <#
        .SYNOPSIS
        Helper function to return the JWT in standard format as a powershell object.

        .DESCRIPTION
        Returns the JWT in standard powershell format which can then be used to interact with the connected environment.

        .PARAMETER BaseURL
        This should be in the format for fqdn without any protocol, paths, or organization added to the URL.

        .PARAMETER Organization
        This is the cluedin organization name. It normally precedes the baseurl. ie. ORGANIZATION.customer.com

        .PARAMETER Username
        This is a username that can access the environment's admin page. It's used for invokes etc.

        .PARAMETER Password
        This is the password to the username. It must be in powershell `securestring` format.

        .EXAMPLE
        PS> Get-CluedInAPIToken -BaseURL 'cluedin.com' -Organization 'customer' -Username 'cluedin' -Password $securePassword

        This send a REST request to the authentication endpoint and return a JWT which is returned to the caller.
    #>

    [CmdletBinding()]
    param(
        [string]$BaseURL = ${env:CLUEDIN_BASEURL},
        [string][Alias('Organisation')]$Organization = ${env:CLUEDIN_ORGANIZATION},
        [Parameter(ParameterSetName = 'Refresh')][string]$RefreshToken = ${env:CLUEDIN_REFRESH_TOKEN},
        [Parameter(ParameterSetName = 'Credentials')][string]$Username,
        [Parameter(ParameterSetName = 'Credentials')][securestring]$Password,
        [switch]$UseHTTP
    )

    switch ($PsCmdlet.ParameterSetName) {
        'Refresh' {
            $body = "grant_type=refresh_token&refresh_token=$RefreshToken&client_id=$Organization"
        }
        'Credentials' {
            $enc_username = [System.Web.HttpUtility]::UrlEncode($Username)
            $enc_password = [System.Web.HttpUtility]::UrlEncode((ConvertFrom-SecureString -AsPlainText $Password))

            $body = "username=$enc_username&password=$enc_password&client_id=$Organization&grant_type=password"
        }
    }

    $protocol = $UseHTTP ? 'http' : 'https'
    $requestUrl = '{0}://{1}.{2}/auth/connect/token' -f $protocol, $Organization, $BaseURL

    $headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
    }

    $response = Invoke-RestMethod -Uri $requestUrl -Method 'POST' -Headers $headers -Body $body

    return $response
}
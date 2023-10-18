function Get-CluedInAPIToken {
    <#
        .SYNOPSIS
        Helper function to return the JWT in standard format as a powershell object.

        .DESCRIPTION
        Returns the JWT in standard powershell format which can then be used to interact with the connected environment.

        .PARAMETER BaseURL
        This should be in the format for fqdn without any protocol, paths, or Organisation added to the URL.

        .PARAMETER Organisation
        This is the cluedin organisation name. It normally precedes the baseurl. ie. ORGANISATION.customer.com

        .PARAMETER Username
        This is a username that can access the environment's admin page. It's used for invokes etc.

        .PARAMETER Password
        This is the password to the username. It must be in powershell `securestring` format.

        .EXAMPLE
        PS> Get-CluedInAPIToken -BaseURL 'cluedin.com' -Organisation 'customer' -Username 'cluedin' -Password $securePassword
        
        This send a REST request to the authentication endpoint and return a JWT which is returned to the caller.
    #>

    [CmdletBinding()]
    param(
        [string]$BaseURL, # just format of dns, no https required. Lets add logic to check it's valid (regex)
        [string]$Organisation, # this is in format of ie. jjr-dev
        [string]$Username,
        [securestring]$Password
    )

    $enc_username = [System.Web.HttpUtility]::UrlEncode($Username)
    $enc_password = [System.Web.HttpUtility]::UrlEncode((ConvertFrom-SecureString -AsPlainText $Password))

    
    $requestUrl =  'https://{0}.{1}/auth/connect/token' -f $Organisation, $BaseURL
    $body = "username=$enc_username&password=$enc_password&client_id=$Organisation&grant_type=password"
    $headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
    }

    $response = Invoke-RestMethod -Uri $requestUrl -Method 'POST' -Headers $headers -Body $body

    return $response
}
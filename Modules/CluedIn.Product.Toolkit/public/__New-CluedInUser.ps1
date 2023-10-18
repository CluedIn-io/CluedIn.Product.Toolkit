function New-CluedInUser {
    [CmdletBinding()]
    param (
        $username,
        $email,
        $baseURL,
        $org,
        $token,
        $Password
    )
    
    begin {
        $JWT = $token.access_token
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Content-Type", "application/x-www-form-urlencoded")
        $headers.Add("Authorization", "Bearer $JWT")
        $enc_username =    [System.Web.HttpUtility]::UrlEncode($username) 
        $enc_email =    [System.Web.HttpUtility]::UrlEncode($email) 
        $enc_password =    [System.Web.HttpUtility]::UrlEncode($Password) 
    }
    
    process {


        $body = "username=$enc_username&password=$enc_password&applicationSubDomain=$org&grant_type=password&confirmpassword=$enc_password&email=$enc_email&AllowEmailDomainSignup=True"
        
        $code = get-MD5 -string $email
        $response = Invoke-RestMethod "$baseURL/auth/api/account/register?&code=$code" -Method 'POST' -Headers $headers -Body $body
        $response
    }
    
    end {
        
    }
}
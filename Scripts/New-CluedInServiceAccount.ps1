# In order to create a service account, you'll need to use the default administrator of CluedIn that isn't Single Sign On
# or an account that has enough permission (not SSO) to create new users.

# Once logged in and authenticated, the service account will be created.

# Variables
$loginUser = 'username@customer.com' # This is the default administrator. Not SSO
$loginUserPassword = '' # This is the default administrator password. Not SSO
$baseUrl = 'customer.com' # the FQDN without org (ie. customer.com in cluedin.customer.com)
$org = 'cluedin' # First part of url (ie. cluedin in cluedin.customer.com)

$serviceAccount = 'serviceaccount@customer.com'
$serviceAccountPassword = 'ChangeMe'

# Authenticate
$encUsername = [System.Web.HttpUtility]::UrlEncode($loginUser)
$encPassword = [System.Web.HttpUtility]::UrlEncode($loginUserPassword)
$params = @{
    Uri = ('https://{0}.{1}/auth/connect/token' -f $org, $baseUrl)
    Method = 'POST'
    Headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
    }
    Body = 'username={0}&password={1}&client_id={2}&grant_type=password' -f @(
        $encUsername, $encPassword, $org
    )
}
$token = Invoke-RestMethod @params

# Create Service Account
$md5 = [Security.Cryptography.MD5CryptoServiceProvider]::new()
$utf8 = [Text.ASCIIEncoding]::ASCII
$bytes = $md5.ComputeHash($utf8.GetBytes($serviceAccount))
$emailcode = [string]::Concat($bytes.foreach{$_.ToString("x2")})
$EC = $emailcode.ToUpper()

$params = @{
    Uri = ('https://{0}.{1}/auth/api/account/register?&code={2}' -f $org, $baseUrl, $EC)
    Method = 'POST'
    Headers = @{
        'Content-Type' = "application/x-www-form-urlencoded"
        Authorization = '{0} {1}' -f $token.token_type, $token.access_token
    }
    Body = "username={0}&password={1}&applicationSubDomain={2}&grant_type=password&confirmpassword={3}&email={4}" -f @(
        $serviceAccount, $serviceAccountPassword, $org, $serviceAccountPassword, $serviceAccount
    )
}

Invoke-RestMethod @params

# Once the user has been created, it'll need enough permission to action the pipelines tasks.
# You can assign it OrganizationAdmin role or create a new role specifically for this.
# It will require the following:
# * Engine: All set to 'None'
# * Management: Data Catalog, Hierachy Builder, Rule Builder, Glossary, Annotation. Set to 'Accountable'. Rest remain as 'None'
# * Governance: All set to 'None'
# * Admin: Tenant Management, Entity Types. Set to 'Accountable'. Rest remain as 'None'
# * Integration: Configured Integrations, Data Source Groups. Set to 'Accountable'. Rest remain as 'None'
# * Consume: Export Targets. Set to 'Accountable'. Rest remain as 'None'
# * Preparation: All set to 'None'
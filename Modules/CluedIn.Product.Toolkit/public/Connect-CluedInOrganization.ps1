function Connect-CluedInOrganization {
    <#
        .SYNOPSIS
        Sets the current PowerShell session to the CluedIn Environment.

        .DESCRIPTION
        Connects and Authenticates to the CluedIn Organization specified when calling the function.
        This stores some Environmental Variables for this session only which won't persist when powershell gets closed.

        The function should be ran before doing any work with a CluedIn Organization

        !!   If ${env:CLUEDIN_HOME} is set to $true, http will be used instead   !!

        .PARAMETER BaseURL
        This is the Base url for the CluedIn environment. This should not include the organization.
        ie. If you normally access on 'org.customer.com', please only use 'customer.com'

        .PARAMETER Organization
        This is the organization to connect to. This can be determined on the url as it precedes the base url.
        ie. If you normally access on 'org.customer.com', please only use 'org'

        .PARAMETER APIToken
        Can pass in a CluedIn API token that grants access to PublicAPI and Server UI Components only

        .PARAMETER Force
        If you need to refresh the JWT, force allows you to skip the existing check. This is useful when testing
        against environments you're destroying and recreating.

        .EXAMPLE
        PS> Connect-CluedInOrganization -BaseURL 'customer.com' -Orgnization 'org'

        This will attempt to connect to https://org.customer.com and authenticate
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BaseURL,
        [Parameter(Mandatory)][Alias('Organisation')][string]$Organization,
        [string]$APIToken,
        [switch]$UseHTTP,
        [switch]$Force
    )

    function tokenOrganization($token) {
        $tokenProperties = ConvertFrom-JWToken -Token $token
        if ($Organization -ne $tokenProperties.OrganizationName) { return $false }

        return $true
    }

    function tokenExpired($token) {
        $tokenProperties = ConvertFrom-JWToken -Token $token
        $tokenExpire = Get-Date -UnixTimeSeconds $tokenProperties.exp
        Write-Debug "tokenExpire: $tokenExpire"
        $refreshRequired = $tokenExpire -lt (Get-Date).AddMinutes(-3)

        return $refreshRequired
    }

    function getCluedInVersion() {
        $uri = '{0}://{1}.{2}/api/status' -f $protocol, $Organization, $BaseUrl
        return [version](Invoke-WebRequest -uri $uri).headers.'x-cluedin-version'[0]
    }

    $protocol = $UseHTTP ? 'http' : 'https'

    $version = getCluedInVersion
    if (!$version) { throw "Issue obtaining version. Version returned: '$version'" }
    if ($version -lt [version]'3.7.0') { throw "This toolkit only supports versions greater than 2023.07/3.7.0" }

    [string]$envVersion = '{0}.{1}.{2}' -f $Version.Major, $Version.Minor, $Version.Build

    if (!$Force) {
        if (${env:CLUEDIN_JWTOKEN}) {
            Write-Verbose "Checking existing token is still valid"
            $skipToken = $true
            $sameOrg = tokenOrganization(${env:CLUEDIN_JWTOKEN})
            if (!$sameOrg) { Write-Verbose "Organization doesn't match"; $skipToken = $false }

            $refresh = tokenExpired(${env:CLUEDIN_JWTOKEN})
            if ($refresh) { Write-Verbose "Token has expired"; $skipToken = $false }

            if ($skipToken) {
                $tokenContent = ${env:CLUEDIN_JWTOKEN}
                Write-Verbose "TokenContent set to existing"
            }
        }
    }

    if (!$skipToken) {
        Write-Verbose "Getting JWT"
        if ($APIToken) {
            $sameOrg = tokenOrganization($APIToken)
            if (!$sameOrg) { throw "Organization doesn't in specified API Token, please investigate"; return }

            $refresh = tokenExpired(${env:CLUEDIN_JWTOKEN})
            if ($refresh) { throw "The specified API Token has expired, please investigate"; return }
            $tokenContent = $APIToken
        }
        else {
            Write-Verbose "Generating JWT based on credentials"
            if ( ${env:CLUEDIN_USERNAME} -and ${env:CLUEDIN_PASSWORD} ) {
                $username = ${env:CLUEDIN_USERNAME}
                $password = ConvertTo-SecureString -String ${env:CLUEDIN_PASSWORD} -AsPlainText -Force
                [PSCredential]$cluedInCredentials = New-Object System.Management.Automation.PSCredential ($username, $password)
            }
            else { $cluedInCredentials = Get-Credential -Title 'CluedIn Organization Login' }

            $tokenParams = @{
                BaseURL = $BaseURL
                Organization = $Organization
                Username = $cluedInCredentials.UserName
                Password = $cluedInCredentials.Password
                UseHTTP = $UseHTTP
            }
            Write-Debug "Params: $($tokenParams | Out-String)"
            $token = Get-CluedInAPIToken @tokenParams
            if (!$token) { throw "Error connecting to CluedIn" }
            $tokenContent = $token.access_token
            $tokenRefresh = $token.refresh_token
            Write-Verbose "Token successfully obtained"
        }
    }

    ${env:CLUEDIN_ORGANIZATION} = $Organization
    ${env:CLUEDIN_BASEURL} = $BaseURL
    ${env:CLUEDIN_CURRENTVERSION} = $envVersion
    ${env:CLUEDIN_ENDPOINT} = '{0}://{1}.{2}' -f $protocol, $Organization, $BaseURL
    ${env:CLUEDIN_JWTOKEN} = $tokenContent
    ${env:CLUEDIN_REFRESH_TOKEN} = $tokenRefresh
    ${env:CLUEDIN_MODULE_PATH} = Split-Path -Path $PSScriptRoot
    ${env:CLUEDIN_ENDPOINT_USEHTTP} = $UseHTTP

    if (Test-CluedInWebConnectivity) {
        Write-Host "Connected to '${env:CLUEDIN_ENDPOINT}' successfully" -ForegroundColor 'Green'
    }
    else { Write-Host "Failure to connect to '${env:CLUEDIN_ENDPOINT}'" -ForegroundColor 'Red' }
}
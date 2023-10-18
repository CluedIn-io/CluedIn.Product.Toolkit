function Connect-CluedInOrganisation {
    <#
        .SYNOPSIS
        Sets the current PowerShell session to the CluedIn Environment.

        .DESCRIPTION
        Connects and Authenticates to the CluedIn Organisation specified when calling the function.
        This stores some Environmental Variables for this session only which won't persist.

        The function should be ran before doing any work with a CluedIn Organisation

        .PARAMETER BaseURL
        This is the Base url for the CluedIn environment. This should not include the organisation.
        ie. If you normally access on 'org.customer.com', please only use 'customer.com'

        .PARAMETER Organisation
        This is the organisation to connect to. This can be determined on the url as it precedes the base url.
        ie. If you normally access on 'org.customer.com', please only use 'org'

        .PARAMETER APIToken
        Can pass in a CluedIn API token that grants access to PublicAPI and Server UI Components only

        .EXAMPLE
        PS> Connect-CluedInOrganisation -BaseURL 'customer.com' -Orgnisation 'org'
        
        This will attempt to connect to https://org.customer.com and authenticate
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BaseURL,
        [Parameter(Mandatory)][string]$Organisation,
        [string]$APIToken
    )

    function NewJWT($token) {
        $tokenProperties = ConvertFrom-JWTToken -Token $token
        Write-Debug "Token Properties: $($tokenProperties | Out-String)"
        if ($Organisation -ne $tokenProperties.OrganizationName) {
            if ($APIToken) { throw "Please check you are using the correct API Token for the given Organisation" }

            Write-Verbose "Current Token doesn't match requested Organisation"
            return $false 
        }

        $tokenExpire = (Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($tokenProperties.exp))
        $refreshRequired = $tokenExpire -lt (Get-Date).AddMinutes(-3)

        return $refreshRequired
    }

    $existingToken = ${env:CLUEDIN_JWTOKEN}
    if ($existingToken) {
        Write-Verbose "Checking existing token is still valid"
        $skipToken = NewJWT($existingToken)
    }
    
    if (!$skipToken) { 
        Write-Verbose "Getting JWT"

        if ($APIToken) { 
            if (NewJWT($APIToken)) { Write-Error "Your API Token has expired. Please generate a new one" }

            Write-Verbose "API Token passed validation"
            $tokenContent = $APIToken 
        }
        else {
            Write-Verbose "Generating JWT based on credentials"
            $cluedInCredentials = Get-Credential -Title 'CluedIn Organisation Login'
            $tokenParams = @{
                BaseURL = $BaseURL 
                Organisation = $Organisation 
                Username = $cluedInCredentials.UserName 
                Password = $cluedInCredentials.Password
            }
            Write-Debug "Params: $($tokenParams | Out-String)"
            $token = Get-CluedInAPIToken @tokenParams
            $tokenContent = $token.Access_token
            Write-Verbose "Token successfully obtained"
        }
    }

    ${env:CLUEDIN_ORGANISATION} = $Organisation
    ${env:CLUEDIN_CURRENTVERSION} = '2023.07' # Read-Host "Current product version in Major.Minor format"
    ${env:CLUEDIN_ENDPOINT} = 'https://{0}.{1}' -f $Organisation, $BaseURL
    ${env:CLUEDIN_JWTOKEN} = $tokenContent

    Write-Host "Connected to '$Organisation' successfully" -ForegroundColor 'Green'
}
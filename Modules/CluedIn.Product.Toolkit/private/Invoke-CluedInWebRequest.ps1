function Invoke-CluedInWebRequest {
    <#
        .SYNOPSIS
        Wrapper to the standard Invoke-RestMethod

        .DESCRIPTION
        Wrapper to the standard Invoke-RestMethod with headers set to the correct configuration

        .EXAMPLE
        PS> Invoke-CluedInWebRequest -Uri 'https://customer.cluedin.com/api/graphql' -Method 'POST' -Body $body

        This will query the endpoint with a GraphQL body.
    #>

    [CmdletBinding()]
    param(
        [string]$Uri,
        [string]$Method = 'GET',
        [string]$Body
    )

    if (!${env:CLUEDIN_JWTOKEN}) { throw "Please run 'Connect-CluedInOrganization' before attempting" }

    $headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = 'Bearer {0}' -f ${env:CLUEDIN_JWTOKEN}
    }

    Try {
        $params = @{
            Method = $Method
            Uri = $Uri
            Headers = $headers
            Body = $Body
            UseBasicParsing = $true
            SkipHttpErrorCheck = $true
        }
        $requestResult = Invoke-WebRequest @params

        if ($requestResult.StatusDescription -eq 'OK') { return ($requestResult.Content | ConvertFrom-Json) }

        if ($requestResult.StatusCode -eq '^401$|^403$') {
            Write-Verbose "Checking JWT Token"
            $shouldRefresh = Get-ShouldRefreshToken -JWT ${env:CLUEDIN_JWTOKEN}
            if ($shouldRefresh) {
                Write-Verbose "Refreshing!"
                Try {
                    $tokenResponse = Get-CluedInAPIToken -RefreshToken ${env:CLUEDIN_REFRESH_TOKEN} -UseHTTP:${$env:CLUEDIN_ENDPOINT_USEHTTP}
                    ${env:CLUEDIN_JWTOKEN} = $tokenResponse.access_token
                    ${env:CLUEDIN_REFRESH_TOKEN} = $tokenResponse.refresh_token
                }
                Catch { Write-Error "Issue refreshing token. Reason: $_"; return }
            }
            else { Write-Error "$($requestResult.StatusDescription)"; return }

            $requestResult = Invoke-WebRequest @params
            if ($requestResult.StatusDescription -eq 'OK') { return ($requestResult.Content | ConvertFrom-Json) }
            else { Write-Error "Refreshed token, but received response: $($requestResult.StatusDescription)"; return }
        }
    }
    Catch { Write-Error "Issue with invoke $_"; return }
}
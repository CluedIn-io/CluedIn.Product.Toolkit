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

    function invokeRequest() {
        $params = @{
            Method = $Method
            Uri = $Uri
            Headers = @{
                'Content-Type' = 'application/json'
                'Authorization' = 'Bearer {0}' -f ${env:CLUEDIN_JWTOKEN}
            }
            Body = $Body
            UseBasicParsing = $true
            SkipHttpErrorCheck = $true
        }

        return Invoke-WebRequest @params
    }

    Try {
        $requestResult = invokeRequest

        if ($requestResult.StatusDescription -eq 'OK') { return ($requestResult.Content | ConvertFrom-Json) }

        if ($requestResult.StatusCode -match '^401$|^403$') {
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

            Write-Verbose "Attempting again"
            $requestResult = invokeRequest
            if ($requestResult.StatusDescription -eq 'OK') { return ($requestResult.Content | ConvertFrom-Json) }
            else { Write-Error "Refreshed token, but received response: $($requestResult.StatusDescription)"; return }
        }
        else { Write-Error "Received code: $($requestResult.StatusCode). Processing request failed." }
    }
    Catch { Write-Error "Issue with invoke $_"; return }
}
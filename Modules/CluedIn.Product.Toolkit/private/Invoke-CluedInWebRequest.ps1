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

    if (!${env:CLUEDIN_JWTOKEN}) { throw "Please run 'Connect-CluedInOrganisation' before attempting" }

    $headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = 'Bearer {0}' -f ${env:CLUEDIN_JWTOKEN}
    }

    Try {
        return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Body $Body -UseBasicParsing
    }
    Catch { Write-Error "Issue with invoke $_"; return }
}
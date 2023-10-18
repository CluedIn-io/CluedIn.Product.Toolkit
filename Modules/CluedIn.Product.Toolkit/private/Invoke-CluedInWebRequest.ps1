function Invoke-CluedInWebRequest {
    <#
        .SYNOPSIS
        Helper function which is a wrapper to the standard Invoke-RestMethod

        .DESCRIPTION
        Helper function which is a wrapper to the standard Invoke-RestMethod

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

    Try { $result = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Body $Body -UseBasicParsing } 
    Catch { Write-Debug $_ }

    return $result
}
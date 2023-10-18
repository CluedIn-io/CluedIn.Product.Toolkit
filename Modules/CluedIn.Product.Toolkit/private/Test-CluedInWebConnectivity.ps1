function Test-CluedInWebConnectivity {
    <#
        .SYNOPSIS
        Tests that the CluedIn endpoint is healthy and reachable.

        .DESCRIPTION
        Tests that the CluedIn endpoint is healthy and reachable.
    #>
    
    [CmdletBinding()]
    param()

    $endpoint = ${env:CLUEDIN_ENDPOINT} + "/api/status"
    Write-Debug "endpoint: $endpoint"

    $status = Invoke-CluedInWebRequest -Uri $endpoint
    Write-Debug "status: $status"
    
    $result = ($status.ServiceStatus -eq 'Green') ? "Success" : "Fail"

    return $result
}
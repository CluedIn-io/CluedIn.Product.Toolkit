function Test-CluedInWebConnectivity {
    <#
        .SYNOPSIS
        Tests that the CluedIn endpoint is healthy and reachable.

        .DESCRIPTION
        Tests that the CluedIn endpoint is healthy and reachable.

        It uses some environmental variable and cannot be ran without running Connect-CluedInOrganisation first.
    #>

    [CmdletBinding()]
    param()

    $endpoint = ${env:CLUEDIN_ENDPOINT} + "/api/status"
    Write-Debug "endpoint: $endpoint"

    $status = Invoke-CluedInWebRequest -Uri $endpoint
    Write-Debug "status: $status"

    $result = ($status.ServiceStatus -eq 'Green') ? $true : $false

    return $result
}
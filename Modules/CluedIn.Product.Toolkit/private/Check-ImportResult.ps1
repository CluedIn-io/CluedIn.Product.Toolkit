function Check-ImportResult {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][Object]$Result,
        [string]$Type = $null
    )

    if ($Result.errors) {
        switch ($Result.errors.message) {
            {$_ -match '409'} { 
                if($Type -eq 'vocab') {
                    Write-Host "Skipping vocab already exists or was unchanged" -ForegroundColor 'Cyan'
                } else {
                    Write-Warning "An entry already exists" 
                }
            }
            default 
            { 
                Write-Warning "Failed: $($Result.errors.message)" 
            }
        }
    }
}
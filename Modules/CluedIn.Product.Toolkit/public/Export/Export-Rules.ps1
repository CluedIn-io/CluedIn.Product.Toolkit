function Export-Rules{
    <#
        .SYNOPSIS
        Wrapper for exporting data source sets

        .DESCRIPTION
        Wrapper for exporting data source sets

        .PARAMETER BackupPath
        The path to the backup folder

        .PARAMETER SelectVocabularies
        Specifies what Rules to export. It supports All, None, and csv format of the Id's

        .EXAMPLE
        PS> Export-Rules -BackupPath "c:\backuplocation"

        This will export all of the data source sets details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupPath,
        [string]$SelectRules = 'None'
    )

    Write-Host "INFO: Exporting Rules" -ForegroundColor 'Green'
    $rulesPath = Join-Path -Path $BackupPath -ChildPath 'Rules'
    $dataPartRulesPath = Join-Path -Path $rulesPath -ChildPath 'DataPart'
    $survivorshipRulesPath = Join-Path -Path $rulesPath -ChildPath 'Survivorship'
    $goldenRecordsRulesPath = Join-Path -Path $rulesPath -ChildPath 'Entity' # Golden Records
    if (!(Test-Path -Path $rulesPath -PathType Container)) {
        New-Item $dataPartRulesPath -ItemType Directory | Out-Null
        New-Item $survivorshipRulesPath -ItemType Directory | Out-Null
        New-Item $goldenRecordsRulesPath -ItemType Directory | Out-Null
    }

    $ruleIds = @()
    switch ($SelectRules) {
        'All' {
            foreach ($i in @('Survivorship', 'DataPart', 'Entity')) {
                $rules = Get-CluedInRules -Scope $i
                if ($rules.data.management.rules.data) { $ruleIds += $rules.data.management.rules.data.id }
            }
        }
        'None' { $null }
        default { $ruleIds = ($SelectRules -Split ',').Trim() }
    }

    foreach ($id in $ruleIds) {
        $rule = Get-CluedInRules -Id $id
        $ruleObject = $rule.data.management.rule
        $rule | Out-JsonFile -Path (Join-Path -Path $rulesPath -ChildPath $ruleObject.scope) -Name $id
    }
}
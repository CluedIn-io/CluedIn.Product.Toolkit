function Import-Rules{
    <#
        .SYNOPSIS
        Imports deduplication projects

        .DESCRIPTION
        Imports deduplication projects

        .PARAMETER RestorePath
        This is the location of the export files

        .EXAMPLE
        PS> Import-Rules -RestorePath "c:\backuplocation"

        This will import all of the export targets
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath
    )
    
    Write-Host "INFO: Importing Rules" -ForegroundColor 'Green'

    $rulesPath = Join-Path -Path $RestorePath -ChildPath 'Rules'

    $rules = Get-ChildItem -Path $rulesPath -Filter "*.json" -Recurse
    foreach ($rule in $rules) {
        $ruleJson = Get-Content -Path $rule.FullName | ConvertFrom-Json -Depth 20
        $ruleObject = $ruleJson.data.management.rule
        Write-Host "Processing Rule: $($ruleObject.name) ($($ruleObject.scope))" -ForegroundColor 'Cyan'
        $exists = Get-CluedInRules -Search $ruleObject.name -Scope $ruleObject.scope

        if (!$exists.data.management.rules.data) {
            Write-Verbose "Creating rule as it does not exist"
            $ruleResult = New-CluedInRule -Name $ruleObject.name -Scope $ruleObject.scope
            Check-ImportResult -Result $ruleResult
            $ruleObject.id = $ruleResult.data.management.createRule.id
        }
        else { 
            $ruleObject.id = $exists.data.management.rules.data.id 

            if($exists.data.management.rules.data.count -gt 1)
            {
                Write-Warning "Multiple matches for rule '$($ruleObject.name)'"
                foreach($item in $exists.data.management.rules.data)
                {
                    if($item.name -eq $ruleObject.name)
                    {
                        $ruleObject.id = $item.id 
                        continue
                    }
                }
            } else {           
                $ruleObject.id = $exists.data.management.rules.data.id 
            }
        }

        Write-Verbose "Setting rule configuration"
        $setRuleResult = Set-CluedInRule -Object $ruleObject
        Check-ImportResult -Result $setRuleResult
    }
}
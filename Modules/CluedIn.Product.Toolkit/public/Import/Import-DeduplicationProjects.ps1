function Import-DeduplicationProjects{
    <#
        .SYNOPSIS
        Wrapper for exporting deduplicationproject logic

        .DESCRIPTION
        Wrapper for exporting deduplicationproject logic

        .PARAMETER RestorePath
        This is the location of the export files ran by Export-CluedInConfig

        .PARAMETER SelectDeduplicationProjects
        Specifies what Deduplication Projects to export. It supports All, None, and csv format of the Id's

        .EXAMPLE
        PS> Export-DeduplicationProjects -BackupPath "c:\backuplocation" -SelectDeduplicationProjects 'All'

        This will export all of the deduplication project details
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RestorePath,
        [string]$SelectDeduplicationProjects = 'None'
    )

    # Variables
    $deduplicationProjectsPath = Join-Path -Path $RestorePath -ChildPath 'DeduplicationProjects'

    Write-Host "INFO: Importing Deduplication Projects" -ForegroundColor 'Green'
    $deduplicationProjects = Get-ChildItem -Path $deduplicationProjectsPath -Filter "*DeduplicationProject.json" -Recurse
    $currentDeduplicationProjects = Get-CluedInDeduplicationProjects
    $currentDeduplicationProjectObjects = $currentDeduplicationProjects.data.management.deDupProjects.data

    foreach ($deduplicationProject in $deduplicationProjects) {
        $deduplicationProjectId = $null

        $deduplicationProjectJson = Get-Content -Path $deduplicationProject.FullName | ConvertFrom-Json -Depth 20
        $deduplicationProjectObject = $deduplicationProjectJson.data.management.deDupProject

        Write-Host "Processing Deduplication Project: $($deduplicationProjectObject.name)" -ForegroundColor 'Green'
        if ($deduplicationProjectObject.name -notin $currentDeduplicationProjectObjects.name) {
            Write-Host "Creating Deduplication Project '$($deduplicationProjectObject.name)'" -ForegroundColor 'Cyan'
            $deduplicationProjectResult = New-CluedInDeduplicationProject -Name $deduplicationProjectObject.name -Object $deduplicationProjectObject
            Check-ImportResult -Result $deduplicationProjectResult

            $deduplicationProjectId = $deduplicationProjectResult.data.management.createDedupProject.id
        }else{
            $deduplicationProjectId = ($currentDeduplicationProjectObjects | Where-Object { $_.name -eq $deduplicationProjectObject.name }).id
            if ($deduplicationProjectId.count -ne 1) { Write-Error "Multiple Deduplication Project Ids returned"; continue }

            Write-Host "Updating Deduplication Project" -ForegroundColor 'Cyan'
            $updateDeduplicationResult = Set-CluedInDeduplicationProject -Id $deduplicationProjectId -Object $deduplicationProjectObject
            Check-ImportResult -Result $updateDeduplicationResult
        }
        
        # Matching Rules
        Write-Host "Processing Matching Rules for $($deduplicationProjectObject.name)" -ForegroundColor 'Cyan'
        $matchingRulePath = Join-Path -Path $deduplicationProjectsPath -ChildPath ('{0}-MatchingRules.json' -f $deduplicationProjectObject.id)
        if (!(Test-Path -Path $matchingRulePath -PathType 'Leaf')) { Write-Warning "No matching rules to import"; continue }

        $deduplicationMatchingRulesJson = Get-Content -Path $matchingRulePath | ConvertFrom-Json -Depth 20
        $deduplicationMatchingRuleObjects = $deduplicationMatchingRulesJson.data.management.deDuplicateProjectRules.data

        $currentDeduplicationMatchingRules = Get-CluedInDeduplicationMatchingRules -Id $deduplicationProjectId
        $currentDeduplicationMatchingRulesObjects = $currentDeduplicationMatchingRules.data.management.deDuplicateProjectRules.data


        foreach($matchingRule in $deduplicationMatchingRuleObjects){
            if ($matchingRule.name -notin $currentDeduplicationMatchingRulesObjects.name) {
                Write-Host "Creating Matching Rule'$($matchingRule.name)'" -ForegroundColor 'Cyan'
                $matchingRuleResult = New-CluedInDeduplicationMatchingRule -DeduplicationProjectId $deduplicationProjectId -Object $matchingRule
                Check-ImportResult -Result $matchingRuleResult
            }else{ 
                $matchingRuleId = ($currentDeduplicationMatchingRulesObjects | Where-Object { $_.name -eq $matchingRule.name }).id
                if ($matchingRuleId.count -ne 1) { Write-Error "Multiple Deduplication Project Ids returned"; continue }

                Write-Host "Updating Matching Rule" -ForegroundColor 'Cyan'
                $updateMatchingRuleResult = Set-CluedInDeduplicationMatchingRule -Id $deduplicationProjectId -MatchingRuleId $matchingRuleId -Object $matchingRule
                Check-ImportResult -Result $updateMatchingRuleResult
            }
        }
    }
}
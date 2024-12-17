function New-CluedInGlossaryTerm {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a Glossary Term against a specified Glossary

        .DESCRIPTION
        GraphQL Query: Creates a Glossary Term against a specified Glossary

        .PARAMETER Name
        The name of the glossary term

        .PARAMETER GlossaryId
        You can run Get-CluedInGlossary to get the given Id. Which can then be used here.

        .PARAMETER RuleSet
        (Optional) Rule set for the created glossary term

        .EXAMPLE
        PS> New-CluedInGlossaryTerm -Name "Sample Term" -GlossaryId 'f86ffc29-1963-4a70-b9a8-73de5f007a42'
        PS> New-CluedInGlossaryTerm -Name "Sample Term" -GlossaryId 'f86ffc29-1963-4a70-b9a8-73de5f007a42' -RuleSet $ruleSet
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Name,
        [guid]$GlossaryId,
        [Parameter(Mandatory = $false)][PSCustomObject]$RuleSet
    )

    function Convert-Rule {
        param (
            [PSCustomObject]$Rule
        )

        # Initialize the output rule with required properties
        $outputRule = @{
            condition    = $Rule.condition
            field        = $Rule.field
            objectTypeId = $Rule.objectTypeId
            operator     = $Rule.operator
            type         = $Rule.type
            value        = $Rule.value
        }

        # Only add 'rules' array if 'type' is 'rule' and there are nested rules
        if ($Rule.type -eq "rule" -and $Rule.rules -and $Rule.rules.Count -gt 0) {
            $outputRule.rules = @()
            foreach ($nestedRule in $Rule.rules) {
                $outputRule.rules += Convert-Rule -Rule $nestedRule
            }
        }

        return $outputRule
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createGlossaryTerm'

    $variables = @{
        term = @{
            name = $Name
            categoryId = $GlossaryId
        }
    }

    # Process the RuleSet if provided
    if ($PSBoundParameters.ContainsKey('RuleSet') -and $RuleSet) {
        $variables.term.ruleSet = @{
            condition = $RuleSet.condition
            rules     = @()
        }

        foreach ($rule in $RuleSet.rules) {
            $variables.term.ruleSet.rules += Convert-Rule -Rule $rule
        }
    }

    $query = @{
        variables = $variables
        query     = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

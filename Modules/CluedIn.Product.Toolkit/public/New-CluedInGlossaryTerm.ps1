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

    $queryContent = Get-CluedInGQLQuery -OperationName 'createGlossaryTerm'

    $variables = @{
        term = @{
            name = $Name
            categoryId = $GlossaryId
        }
    }

    if ($PSBoundParameters.ContainsKey('RuleSet') -and $RuleSet)
    {
        $variables.ruleSet = $RuleSet
    }

    $query = @{
        variables = $variables
        query     = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

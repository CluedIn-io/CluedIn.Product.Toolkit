function Set-CluedInRule {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a Rule's configuration

        .DESCRIPTION
        GraphQL Query: Sets a Rule's configuration

        .PARAMETER Object
        Due to the complexity of the function, it needs to be passed in as a PSCustomObject

        You can get a sample by running Get-CluedInRules and filtering it down to the rule configuration

        .EXAMPLE
        PS> Set-CluedInRule -Object $sampleRuleObject
    #>

    [CmdletBinding()]
    param(
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveRule'

    $query = @{
        query = $queryContent
        variables = @{
            rule = @{
                id = $Object.id
                name = $Object.name
                isActive = $Object.isActive
                description = $Object.description
                scope = $Object.scope
                condition = $Object.condition
                rules = $Object.rules
            }
        }
    }

    return Invoke-CluedInGraphQL -Query $query
}
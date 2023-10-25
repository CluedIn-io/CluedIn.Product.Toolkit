function New-CluedInRule {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Rule

        .DESCRIPTION
        GraphQL Query: Creates a New Rule

        .PARAMETER Name
        This is the display name of the rule

        .PARAMETER Scope
        This is where the rule will reside

        .EXAMPLE
        PS> New-CluedInRule -RuleName 'TestRule' -Scope 'Survivorship'

        This will create a rule called 'TestRule' under the Survivorship category
    #>

    [CmdletBinding()]
    param(
        [string]$Name,
        [ValidateSet('Survivorship', 'DataPart', 'Entity')][string]$Scope
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createRule'

    $query = @{
        variables = @{
            rule = @{
                name = $Name
                scope = $Scope
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
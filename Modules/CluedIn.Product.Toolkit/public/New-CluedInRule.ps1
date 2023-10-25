function New-CluedInRule {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Rule

        .DESCRIPTION
        GraphQL Query: Creates a New Rule

        .EXAMPLE
        PS> New-CluedInRule -RuleName 'TestRule'

        This will query will return mapping id '10' for the connected CluedIn Organisation
    #>

    [CmdletBinding()]
    param(
        [string]$RuleName,
        [ValidateSet('Survivorship', 'DataPart', 'Entity')][string]$Scope,
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createRule'

    $query = @{
        variables = @{
            rule = @{
                name = 'TestRule'
                scope = $Scope
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
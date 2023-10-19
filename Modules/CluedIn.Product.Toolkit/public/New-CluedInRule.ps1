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
        [string]$RuleName
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createRule'

    $query = @{
        variables = @{
            rule = @{
                name = 'TestRule'
                scope = 'Survivorship'
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
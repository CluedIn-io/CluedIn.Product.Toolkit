function Get-CluedInRules {
    <#
        .SYNOPSIS
        GraphQL Query: Returns created rules in CluedIn depending on Scope

        .DESCRIPTION
        GraphQL Query: Returns created rules in CluedIn depending on Scope

        .PARAMETER Id
        For entire rule configuration, Id is required. It's possible to get the rule using search, and then using the returned
        result to then query the Id for full configuration of a singular rule.

        .PARAMETER Search
        If you want to narrow the results, speficy a string here. By default, will return all rules for a given scope
        It's not a hard match.

        Returned data is less detailed than using Id

        .PARAMETER Scope
        CluedIn currently includes 3 types of rules. Survivorship, Data Part, and Golden Records (Entity).
        Depending on the rules you want returned, you need to specify the appropriate scope.

        .EXAMPLE
        PS> Get-CluedInRules -Scope 'DataPart'

        Will return all rules from Data Part
    #>

    [CmdletBinding(DefaultParameterSetName = 'Search')]
    param(
        [Parameter(ParameterSetName = 'Id')][guid]$Id,
        [Parameter(ParameterSetName = 'Search')][string]$Search = "",
        [Parameter(ParameterSetName = 'Search', Mandatory)][ValidateSet('Survivorship', 'DataPart', 'Entity')][string]$Scope
    )

    switch ($PsCmdlet.ParameterSetName) {
        'Search' {
            $queryContent = Get-CluedInGQLQuery -OperationName 'getRules'
            $query = @{
                variables = @{
                    searchName = $Search
                    scope = $Scope
                }
                query = $queryContent
            }
        }
        'Id' {
            $queryContent = Get-CluedInGQLQuery -OperationName 'getRule'
            $query = @{
                variables = @{
                    id = $Id
                }
                query = $queryContent
            }
        }
    }

    return Invoke-CluedInGraphQL -Query $query
}
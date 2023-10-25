function Get-CluedInRules {
    [CmdletBinding(DefaultParameterSetName = 'Search')]
    param(
        [Parameter(ParameterSetName = 'Id')][guid]$Id,
        [Parameter(ParameterSetName = 'Search')][string]$Search = "",
        [Parameter(Mandatory)][ValidateSet('Survivorship', 'DataPart', 'Entity')][string]$Scope
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
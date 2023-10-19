function Get-CluedInRules {
    [CmdletBinding()]
    param(
        [guid]$Id
    )

    switch ($Id) {
        '' {
            $queryContent = Get-CluedInGQLQuery -OperationName 'getRules'
            $query = @{ 
                variables = @{
                    scope = 'Survivorship'
                }
                query = $queryContent 
            }
        }
        !'' {
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
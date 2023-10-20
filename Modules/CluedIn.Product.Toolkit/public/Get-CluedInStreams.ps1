function Get-CluedInStreams {
    [CmdletBinding()]
    param(
        [guid]$Id,
        [Parameter(Mandatory)][ValidateSet('Survivorship', 'DataPart', 'Entity')][string]$Scope
    )

    switch ($Id) {
        '' {
            $queryContent = Get-CluedInGQLQuery -OperationName 'getRules'
            $query = @{ 
                variables = @{
                    scope = $Scope
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
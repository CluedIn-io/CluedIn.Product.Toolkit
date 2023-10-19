function Get-CluedInOrganisationFeatures {
    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getRules'

    $query = @{ 
        variables = @{
            scope = 'Survivorship'
        }
        query = $queryContent 
    }

    return Invoke-CluedInGraphQL -Query $query
}
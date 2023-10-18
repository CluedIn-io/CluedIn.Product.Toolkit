function Get-CluedInDataSource {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information based on a data source id

        .DESCRIPTION
        GraphQL Query: Returns information based on a data source id

        .EXAMPLE
        PS> Get-CluedInDataSet -Id 10
        
        This will query will return data source id '10' for the connected CluedIn Organisation
    #>

    [CmdletBinding()]
    param(
        [int]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getDataSourceById'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
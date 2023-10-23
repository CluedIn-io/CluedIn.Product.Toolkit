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
        [Parameter(ParameterSetName = 'Specified')][int]$Id,
        [Parameter(ParameterSetName = 'Search')][string]$Search
    )

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $dataSourceSets = Get-CluedInDataSourceSet
        $dataSourceSetsObject = $dataSourceSets.data.inbound.dataSourceSets.data.dataSources
        $Id = $dataSourceSetsObject | Where-Object {$_.name -match "^$Search$"} | Select-Object -ExpandProperty id
        if (!$Id) { return }
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'getDataSourceById'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
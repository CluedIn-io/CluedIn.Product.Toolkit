function Get-CluedInDataSource {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information on a data source

        .DESCRIPTION
        GraphQL Query: Returns information on a data source

        You can search by Id or Name field. You cannot specify both

        .PARAMETER Id
        This is the id of a data source which is integer

        .PARAMETER Search
        This allows you to get the data source by searching for the name instead of Id

        .EXAMPLE
        PS> Get-CluedInDataSource -Id 10

        This query will return data source id '10' for the connected CluedIn Organization

        .EXAMPLE
        PS> Get-CluedInDataSource -Search "Sample DataSet"

        This query will return the data sources that match the search criteria. This is a hard match and won't wildcard.
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'Specified')][int]$Id,
        [Parameter(ParameterSetName = 'Search')][string]$Search
    )

    if ($PsCmdlet.ParameterSetName -eq 'Search') {
        $dataSourceSets = Get-CluedInDataSourceSet
        $dataSourceSetsObject = $dataSourceSets.data.inbound.dataSourceSets.data.dataSources
        $regex = '^{0}$' -f [Regex]::Escape($Search)
        $dataSourceIds = $dataSourceSetsObject | Where-Object { $_.name -match $regex } | Select-Object -ExpandProperty id

        if($dataSourceIds.count -gt 1){
            Write-Warning "Multiple matches found for the data source '${search}'"
            return 
        }

        $Id = $dataSourceIds
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
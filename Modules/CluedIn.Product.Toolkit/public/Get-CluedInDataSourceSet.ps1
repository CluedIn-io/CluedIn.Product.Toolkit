function Get-CluedInDataSourceSet {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all Data Source Sets

        .DESCRIPTION
        GraphQL Query: Returns all Data Source Sets  

        .EXAMPLE
        PS> Get-CluedInDataSourceGroup 
        
        This will query will all Data Source Sets
    #>

    [CmdletBinding()]
    param ()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAllDataSourceSet'

    $query = @{
        variables = @{
            pageSize = 10
            searchName = ""
            page = 0
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
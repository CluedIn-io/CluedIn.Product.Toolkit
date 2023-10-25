function Get-CluedInDataSourceSet {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all Data Source Sets

        .DESCRIPTION
        GraphQL Query: Returns all Data Source Sets

        .PARAMETER Search
        If not specified, it will return all results. However, you can narrow the return results by using this parameter.
        It does not hard match

        .EXAMPLE
        PS> Get-CluedInDataSourceSet

        This will return all Data Source Sets

        .EXAMPLE
        PS> Get-CluedInDataSourceSet -Search "Sample Data Source Set"

        This will return all results that contain "Sample Data Source Set" as part of their name. Its not a hard match.
    #>

    [CmdletBinding()]
    param (
        [string]$Search = ""
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAllDataSourceSet'

    $query = @{
        variables = @{
            pageSize = 10
            searchName = $Search
            page = 0
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
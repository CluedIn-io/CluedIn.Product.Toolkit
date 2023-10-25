function Get-CluedInEntityType {
    <#
        .SYNOPSIS
        GraphQL Query: Returns Entity Types

        .DESCRIPTION
        GraphQL Query: Returns Entity Types

        .PARAMETER Search
        You can specify a Search parameter and it will narrow down the results
        It is not a hard match

        .EXAMPLE
        PS> Get-CluedInEntityType

        This query will return all entity types

        .EXAMPLE
        PS> Get-CluedInEntityType -Search "Sample Entity"

        This query will return entity type that use 'Sample Entity' in the displayName
    #>

    [CmdletBinding()]
    param (
        [string]$Search = ""
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getEntityType'

    $query = @{
        variables = @{
            pageSize = 20
            searchName = $Search
            pageNumber = 1
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}





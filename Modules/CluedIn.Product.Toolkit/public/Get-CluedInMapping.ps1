function Get-CluedInMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all mappings

        .DESCRIPTION
        GraphQL Query: Returns all mappings

        .EXAMPLE
        PS> Get-CluedInMapping -Id 10

        This will query will return mapping id '10' for the connected CluedIn Organisation

        .EXAMPLE
        PS> Get-CluedInMapping

        This will query will return all mappings for the connected CluedIn Organisation
    #>

    [CmdletBinding()]
    param(
        [int]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAnnotationById'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Get-CluedInAnnotations {
    <#
        .SYNOPSIS
        GraphQL Query: Gets all annotations for a given data set

        .DESCRIPTION
        GraphQL Query: Gets all annotations for a given data set

        .EXAMPLE
        PS> Get-CluedInAnnotations
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
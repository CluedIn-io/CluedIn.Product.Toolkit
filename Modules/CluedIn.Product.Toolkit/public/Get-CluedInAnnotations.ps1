function Get-CluedInAnnotations {
    <#
        .SYNOPSIS
        GraphQL Query: Gets all annotations for a given data set

        .DESCRIPTION
        GraphQL Query: Gets all annotations for a given data set

        .PARAMETER Id
        This is the AnnotationId assigned to a DataSet. You can query Data Sets to see what annotation is assigned to it.
        You can then use this function to pull back the annotation configuration.

        .EXAMPLE
        PS> Get-CluedInAnnotations -Id 1
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Id
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
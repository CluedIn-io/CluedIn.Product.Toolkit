function Get-CluedInAnnotationCodes {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about Annotation Codes

        .DESCRIPTION
        GraphQL Query: Returns information about Annotation Codes

        .PARAMETER Id
        The annotation Id that you want to retrieve the Annotation Codes for

        .EXAMPLE
        PS> Get-CluedAnnotationCodes
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAnnotationCodes'

    $query = @{
        variables = @{
            annotationId = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
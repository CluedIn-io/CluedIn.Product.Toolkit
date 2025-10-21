function Set-CluedInAnnotationCode {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new Annotation Code

        .DESCRIPTION
        GraphQL Query: Creates a new Annotation Code

        .PARAMETER Id
        The id of the annotation code that will be updated

        .PARAMETER Configuration
        The json object that was exported

        .EXAMPLE
        PS> Set-CluedInAnnotationCode -Id 1 -Configuration $configuration 
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][PSCustomObject]$Configuration
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'updateAnnotationCode'

    $query = @{
        variables = @{
            id = $Id
            annotationCode = @{
                entityCodeOrigin = $Configuration.entityCodeOrigin
                sourceCode = $Configuration.sourceCode
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
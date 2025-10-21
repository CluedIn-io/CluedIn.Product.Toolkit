function New-CluedInAnnotationCode {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new Pre Processing Data Set Rule

        .DESCRIPTION
        GraphQL Query: Creates a new Pre Processing Data Set Rule

        .PARAMETER AnnotationId
        The annotation id that the preprocess rule will be assigned to

        .PARAMETER Configuration
        The json object that was exported

        .EXAMPLE
        PS> New-CluedInAnnotationCode -AnnotationId 1 -Configuration $configuration 
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$AnnotationId,
        [Parameter(Mandatory)][PSCustomObject]$Configuration
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createAnnotationCode'

    $query = @{
        variables = @{
            annotationCode = @{
                annotationId     = $AnnotationId
                vocabKey         = $Configuration.vocabKey
                entityCodeOrigin = $Configuration.entityCodeOrigin
                key              = $Configuration.key
                type             = $Configuration.type
                sourceCode       = $Configuration.sourceCode
            }
        }
        query     = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

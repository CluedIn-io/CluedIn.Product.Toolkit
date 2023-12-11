function Set-CluedInAnnotationEntityCodes {
    <#
        .SYNOPSIS
        GraphQL Query: Sets specific settings for Annotations

        .DESCRIPTION
        GraphQL Query: Sets specific settings for Annotations

        .PARAMETER Id
        This is the AnnotationId that we're setting this against

        .PARAMETER Object
        Due to the complexity of the function, it needs to be passed in as a PSCustomObject

        You can get a sample by filtering down Get-CluedInAnnotation

        .EXAMPLE
        PS> Set-CluedInAnnotationEntityCodes -Id 1 -Object $annotationObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'modifyBatchVocabularyClueMappingConfiguration'

    $query = @{
        variables = @{
            annotationId = $Id
            batchPropertyMappings = @{
                propertyMappingSettings = @(
                    @{
                        vocabKey = $Object.vocabKey
                        entityCodeOrigin = $Object.entityCodeOrigin
                        useAsEntityCode = $Object.useAsEntityCode
                        useSourceCode = $Object.useSourceCode
                    }
                )
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
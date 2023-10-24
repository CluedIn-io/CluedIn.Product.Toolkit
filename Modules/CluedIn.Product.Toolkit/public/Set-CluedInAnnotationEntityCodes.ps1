function Set-CluedInAnnotationEntityCodes {
    <#
        .SYNOPSIS
        GraphQL Query: Sets specific settings for Annotations

        .DESCRIPTION
        GraphQL Query: Sets specific settings for Annotations

        .EXAMPLE
        PS> Set-CluedInAnnotation
    #>

    [CmdletBinding()]
    param(
        [int]$Id,
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'modifyBatchVocabularyClueMappingConfiguration'

    $query = @{
        variables = @{
            annotationId = $Id
            batchPropertyMappings = @{
                propertyMappingSettings = @(
                    @{
                        vocabKey = $Object.vocabularyKey.key
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
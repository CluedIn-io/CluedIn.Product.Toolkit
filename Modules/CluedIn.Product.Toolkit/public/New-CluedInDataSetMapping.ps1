function New-CluedInDataSetMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Adds an annotation mapping to a dataset

        .DESCRIPTION
        GraphQL Query: Adds an annotation mapping to a dataset

        .PARAMETER DataSetId
        This is the data set you'd like to apply the annotation mapping to

        .PARAMETER Object
        Due to the complexity of the function, it needs to be passed in as a PSCustomObject

        You can get a sample object but calling Get-CluedInAnnotation

        .EXAMPLE
        PS> New-CluedInDataSetMapping -DataSetId 'cf5a8ac4-95eb-42e5-a93e-a372e22aa439' -Object $annotationObject
    #>

    [CmdletBinding()]
    param(
        [guid]$DataSetId,
        [string]$VocabularyId,
        [string]$VocabularyKeyId,
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'addPropertyMappingToCluedMappingConfiguration'

    $query = @{
        variables =@{
            dataSetId = $DataSetId
            propertyMappingConfiguration = @{
                originalField = $Object.originalField
                useAsAlias = $false
                useAsEntityCode = $false
                vocabularyKeyConfiguration = @{
                    new = $false
                    vocabularyId = $VocabularyId
                    vocabularyKeyId = $VocabularyKeyId
                }
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
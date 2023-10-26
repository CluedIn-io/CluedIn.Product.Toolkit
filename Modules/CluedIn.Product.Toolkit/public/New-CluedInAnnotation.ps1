function New-CluedInAnnotation {
    <#
        .SYNOPSIS
        GraphQL Query: Creates the Data Set mapping (annotations)

        .DESCRIPTION
        GraphQL Query: Creates the Data Set mapping (annotations)

        .PARAMETER Object
        Because this is a complex function, you need to create a PSCustomObject to use.
        You can see a sample by using Get-CluedInAnnotation, and filtering to the property 'annotation'

        .EXAMPLE
        PS> $annotationJson = Get-Content -Path $annotationPath | ConvertFrom-Json -Depth 20
        PS> $annotationObject = $annotationJson.data.preparation.annotation
        PS> New-CluedInAnnotation -Object $annotationObject
    #>

    [CmdletBinding()]
    param(
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createManualAnnotation'

    $query = @{
        variables =@{
            dataSetId = $Object.dataSetId
            type = $Object.type
            mappingConfiguration = @{
                entityTypeConfiguration = @{
                    new = $false
                    icon = $Object.entityTypeConfiguration.icon
                    entityType = $Object.entityTypeConfiguration.entityType
                    displayName = $Object.entityTypeConfiguration.displayName
                }
                ignoredFields = @()
                vocabularyConfiguration = @{
                    new = $false
                    vocabularyName = $Object.vocabulary.vocabularyName
                    keyPrefix = $Object.vocabulary.keyPrefix
                    vocabularyId = $Object.vocabulary.vocabularyId
                }
            }
            isDynamicVocab = $Object.isDynamicVocab
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
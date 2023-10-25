function New-CluedInEdgeMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Creates an edge mapping

        .DESCRIPTION
        GraphQL Query: Creates an edge mapping

        .PARAMETER AnnotationId
        This is the Id of an annotation which is associated to a data set

        .PARAMETER Object
        Due to the complexity of the function, it needs to be passed in as a PSCustomObject

        You can get a sample by running Get-CluedInAnnotation and filtering down to the annotation mappings

        .EXAMPLE
        PS> New-CluedInEdgeMapping -AnnotationId 1 -Object $annotationMappingObject
    #>

    [CmdletBinding()]
    param(
        [int]$AnnotationId,
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'addEdgeMapping'

    $query = @{
        variables =@{
            annotationId = $AnnotationId
            edgeConfiguration = @{
                edgeProperties = @(
                    @{
                        originalField = $object.edgeProperties.originalField
                        vocabularyKeyConfiguration = @{
                            new = $false
                            vocabularyId = $object.edgeProperties.vocabularyKey.vocabularyId
                            vocabularyKeyId = $object.edgeProperties.vocabularyKey.vocabularyKeyId
                            vocabularyKeyName = $object.edgeProperties.vocabularyKey.name
                            displayName = $object.edgeProperties.vocabularyKey.displayName
                            dataType = $object.edgeProperties.vocabularyKey.dataType
                            storage = 'Typed'
                            key = $object.edgeProperties.vocabularyKey.key
                            groupName = $object.edgeProperties.vocabularyKey.groupName
                        }
                    }
                )
                entityTypeConfiguration = @{
                    new = $false
                    icon = $object.entityTypeConfiguration.icon
                    entityType = $object.entityTypeConfiguration.entityType
                    displayName = $object.entityTypeConfiguration.displayName
                }
                edgeType = $object.edgeType
                origin = $object.origin
                direction = $object.direction
            }
            key = $object.key
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
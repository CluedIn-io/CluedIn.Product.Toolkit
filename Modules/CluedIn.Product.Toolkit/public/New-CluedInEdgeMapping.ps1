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
                entityTypeConfiguration = if ($null -eq $object.entityTypeConfiguration.entityType) {
                    @{}
                } else {
                    @{
                        new = $false
                        icon = $object.entityTypeConfiguration.icon
                        entityType = $object.entityTypeConfiguration.entityType
                        displayName = $object.entityTypeConfiguration.displayName
                    }
                }
                edgeProperties = if (-not $object.edgeProperties) {
                    @() # This doesnt serialize to [] in JSON for some reason so added a work around below
                } else { 
                    $object.edgeProperties | ForEach-Object {
                        @{
                            originalField = $_.originalField
                            vocabularyKeyConfiguration = @{
                                new = $false
                                vocabularyId = $_.vocabularyKey.vocabularyId
                                vocabularyKeyId = $_.vocabularyKey.vocabularyKeyId
                                vocabularyKeyName = $_.vocabularyKey.name
                                displayName = $_.vocabularyKey.displayName
                                dataType = $_.vocabularyKey.dataType
                                storage = 'Typed'
                                key = $_.vocabularyKey.key
                                groupName = $_.vocabularyKey.groupName
                            }
                        }
                    }
                }
                edgeType = $object.edgeType
                origin = $object.origin
                direction = if ([string]::IsNullOrEmpty($object.direction)) { $null } else { $object.direction }
                dataSetId = if ([string]::IsNullOrEmpty($object.dataSetId)) { $null } else { $object.dataSetId }
                dataSourceGroupId = if ([string]::IsNullOrEmpty($object.dataSourceGroupId)) { $null } else { $object.dataSourceGroupId }
                dataSourceId = if ([string]::IsNullOrEmpty($object.dataSourceId)) { $null } else { $object.dataSourceId }
            }
            key = $object.key
        }
        query = $queryContent
    }

    # This is the workaround for the failing array serialization mentioned above
    if($null -eq $query.variables.edgeConfiguration.edgeProperties){
        $query.variables.edgeConfiguration.edgeProperties = @()
    }
    return Invoke-CluedInGraphQL -Query $query
}
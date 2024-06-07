function Set-CluedInDataSetMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Sets an annotation mapping on a dataset

        .DESCRIPTION
        GraphQL Query: Set an annotation mapping on a dataset

        .EXAMPLE
        PS> Set-CluedInDataSetMapping -DataSetId 'cf5a8ac4-95eb-42e5-a93e-a372e22aa439' -PropertyMappingConfiguration $propertyMappingConfig
    #>

    [CmdletBinding()]
    param(
        [guid]$DataSetId,
        [hashtable]$PropertyMappingConfiguration
    )

    if ($PropertyMappingConfiguration.key) {
        $queryContent = Get-CluedInGQLQuery -OperationName 'updateAnnotationMappingInDataSet'
        $query = @{
            variables = @{
                dataSetId = $DataSetId
                fieldMappings = $PropertyMappingConfiguration
            }
            query = $queryContent
        }
    }
    else {
        $queryContent = Get-CluedInGQLQuery -OperationName 'updatePropertyMappingInClueMappingConfig'

        $query = @{
            variables = @{
                dataSetId = $DataSetId
                propertyMappingConfiguration = $PropertyMappingConfiguration
            }
            query = $queryContent
        }
    }

    return Invoke-CluedInGraphQL -Query $query
}
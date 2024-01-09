function Remove-CluedInDataSetMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Removes an annotation mapping on a dataset

        .DESCRIPTION
        GraphQL Query: Removes an annotation mapping on a dataset

        .PARAMETER DataSetId
        This is the data set you'd like to apply the annotation mapping to

        .PARAMETER PropertyId
        This is the field mappings Id

        .EXAMPLE
        PS> Remove-CluedInDataSetMapping -DataSetId 'cf5a8ac4-95eb-42e5-a93e-a372e22aa439' -PropertyId '2473adea-dd43-4ec6-b17f-5c99702a849d'
    #>

    [CmdletBinding()]
    param(
        [guid]$DataSetId,
        [guid]$PropertyId
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'deleteAnnotationMappingInDataSet'

    $query = @{
        variables = @{
            dataSetId = $DataSetId
            propertyId = $PropertyId
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
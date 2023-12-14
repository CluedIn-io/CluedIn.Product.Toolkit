function Set-CluedInDataSetMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Sets an annotation mapping to a dataset

        .DESCRIPTION
        GraphQL Query: Set an annotation mapping to a dataset

        .EXAMPLE
        PS> New-CluedInDataSetMapping -DataSetId 'cf5a8ac4-95eb-42e5-a93e-a372e22aa439' -Object $annotationObject
    #>

    [CmdletBinding()]
    param(
        [guid]$DataSetId,
        [array]$FieldMappings
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'updateAnnotationMappingInDataSet'

    $query = @{
        variables = @{
            dataSetId = $DataSetId
            fieldMappings = @(
                @{
                    originalField = $Object.originalField
                    key = '--ignore--'
                },
                @{
                    id = "26D2BA68-D12A-47AB-BC18-9ACCC6CD9B4B"
                    originalField = "AccountShortNameC"
                    key = "ajgglobalniche.AJGGlobalIndustryNicheName"
                }
            )
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
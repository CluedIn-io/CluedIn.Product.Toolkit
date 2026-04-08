function Set-CluedInAnnotationProperties {
    <#
        .SYNOPSIS
        GraphQL Query= Sets annotation properties for a given annotation

        .DESCRIPTION
        GraphQL Query= Sets annotation properties for a given annotation

        .PARAMETER Id
        This is the Id of the annotation for which properties are being updated

        .PARAMETER Object
        This is an array of property mapping objects to be set for the annotation.

        .EXAMPLE
        PS> Set-CluedInAnnotationProperties -Id '1' -Object $ManualDataEntryProjectObject
    #>

    param(
        $Id,
        [PSCustomObject[]]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'modifyBatchVocabularyClueMappingConfiguration'

    $propertyMappingSettings = $Object | ForEach-Object {
        @{
            vocabKey         = $_.vocabKey
            entityCodeOrigin = $_.entityCodeOrigin
            useAsEntityCode  = $_.useAsEntityCode
            useSourceCode    = $_.useSourceCode
        }
    }

    $query = @{
        query     = $queryContent
        variables = @{
            annotationId          = $Id
            batchPropertyMappings = @{
                propertyMappingSettings = $propertyMappingSettings
            }
        }  
    }

    return Invoke-CluedInGraphQL -Query $query
}
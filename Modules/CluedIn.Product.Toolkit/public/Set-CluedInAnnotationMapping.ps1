function Set-CluedInAnnotationMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a specified admin settings

        .DESCRIPTION
        GraphQL Query: Sets a specified admin settings

        .EXAMPLE
        PS> Set-CluedInAdminSettings
    #>

    [CmdletBinding()]
    param(
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'updateAnnotationMappingInDataSet'

    $query = @{
        variables =@{
            dataSetId = $Object.dataSetId
            fieldMappings = @(
                @{
                    id = $guid # No idea how we can get this
                    originalField = $null
                    key = $Object.annotationProperties.vocabKey
                }
            )
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
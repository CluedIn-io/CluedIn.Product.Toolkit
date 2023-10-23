function New-CluedInDataSetMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Adds an annotation mapping

        .DESCRIPTION
        GraphQL Query: Adds an annotation mapping

        .EXAMPLE
        PS> Set-CluedInAdminSettings
    #>

    [CmdletBinding()]
    param(
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'addPropertyMappingToCluedMappingConfiguration'

    $query = @{
        variables =@{
            dataSetId = $Object.dataSetId
            propertyMappingConfiguration = @{
                originalField = $Object.originalField
                useAsAlias = $false
                useAsEntityCode = $false
                vocabularyKeyConfiguration = @{
                    new = $false
                    vocabularyId = $Object.vocabularyId
                    vocabularyKeyId = $Object.vocabularyKeyId
                }
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
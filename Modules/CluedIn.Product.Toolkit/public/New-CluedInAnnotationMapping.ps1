function New-CluedInAnnotationMapping {
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
                originalField = ''
                useAsAlias = $false
                useAsEntityCode = $false
                vocabularyKeyConfiguration = @{
                    new = $false
                    vocabularyId = 'b63f1890-8535-0bb9-b0d3-8f4dea287e5c'
                    vocabularyKeyId = 'af5a88b3-0203-97e7-9ebd-d3e266291cc2'
                }
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Set-CluedInVocabulary {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the configuration against a vocabulary

        .DESCRIPTION
        GraphQL Query: Sets the configuration against a vocabulary

        .EXAMPLE
        PS> Set-CluedInVocabulary -Object $VocabularyObject

        Updates the configuration of the passed in vocabulary with the settings contained within the object.
    #>

    [CmdletBinding()]
    param(
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveVocabulary'

    $query = @{
        variables = @{
            vocabulary = @{
                vocabularyId = $Object.vocabularyId
                vocabularyName = $Object.vocabularyName
                entityTypeConfiguration = @{
                    icon = $Object.entityTypeConfiguration.icon
                    entityType = $Object.entityTypeConfiguration.EntityType
                    displayName = $Object.entityTypeConfiguration.DisplayName
                }
                keyPrefix = $Object.keyPrefix
                providerId = $Object.providerId
                description = $Object.description
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
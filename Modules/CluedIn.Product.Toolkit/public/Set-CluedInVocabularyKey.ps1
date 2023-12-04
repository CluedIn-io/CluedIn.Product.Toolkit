function Set-CluedInVocabularyKey {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the configuration against a vocabulary key

        .DESCRIPTION
        GraphQL Query: Sets the configuration against a vocabulary key

        .EXAMPLE
        PS> Set-CluedInVocabularyKey -Object $VocabularyObject

        Updates the configuration of the passed in vocabulary key with the settings contained within the object.
    #>

    [CmdletBinding()]
    param(
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveVocabularyKey'

    $query = @{
        variables = @{
            vocabularyKey = @{
                vocabularyId = $Object.vocabularyId
                vocabularyKeyId = $Object.vocabularyKeyId
                displayName = $Object.displayName
                name = $Object.name
                isVisible = $Object.isVisible
                groupName = $Object.groupName
                dataAnnotationsIsEditable = $Object.dataAnnotationsIsEditable
                dataAnnotationsIsNullable = $Object.dataAnnotationsIsNullable
                dataAnnotationsIsPrimaryKey = $Object.dataAnnotationsIsPrimaryKey
                dataAnnotationsIsRequired = $Object.dataAnnotationsIsRequired
                dataAnnotationsMaximumLength = $Object.dataAnnotationsMaximumLength
                dataAnnotationsMinimumLength = $Object.dataAnnotationsMinimumLength
                dataType = $Object.dataType
                storage = $Object.storage
                dataClassificationCode = $Object.dataClassificationCode
                description = $Object.description
                mapsToOtherKeyId = $Object.mapsToOtherKeyId
                isValueChangeInsignificant = $Object.isValueChangeInsignificant
                glossaryTermId = $Object.glossaryTermId
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
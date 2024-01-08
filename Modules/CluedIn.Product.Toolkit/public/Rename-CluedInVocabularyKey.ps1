function Rename-CluedInVocabularyKey {
    <#
        .SYNOPSIS
        GraphQL Query: Renames a vocabulary key

        .DESCRIPTION
        GraphQL Query: Renames a vocabulary key

        .PARAMETER NewName
        New name of the vocabulary key

        .PARAMETER VocabularyId
        guid of the vocabulary that is being updated

        .PARAMETER VocabularyKeyId
        guid of the vocabulary key that is being updated

        .EXAMPLE
        PS> Rename-CluedInVocabularyKey -NewName "TestName2" -VocabularyId '19a4e459-b2b4-4181-b000-9c26afd645f3' -VocabularyKeyId 'db80b8a7-f3ec-4661-ad52-db9b63113461'
    #>

    param(
        [Parameter(Mandatory)][string]$NewName,
        [Parameter(Mandatory)][guid]$VocabularyId,
        [Parameter(Mandatory)][guid]$VocabularyKeyId
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'renameVocabularyKey'

    $query = @{
        variables =@{
            newName = $NewName
            vocabularyId = $VocabularyId
            vocabularyKeyId = $VocabularyKeyId
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
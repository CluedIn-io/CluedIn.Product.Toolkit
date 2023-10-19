function New-CluedInVocabularyKey {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Vocabulary Key

        .DESCRIPTION
        GraphQL Query: Creates a New Vocabulary Key

        .EXAMPLE
        PS> New-CluedInVocabularyKey
    #>

    param(
        [string]$DisplayName, 
        [string]$GroupName,
        [string]$DataType,
        [string]$Description,
        [string]$Prefix,
        [guid]$VocabId
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createVocabularyKey' # This is technically `createVocabulary`

    $query = @{
        variables =@{
            vocabularyKey = @{
                vocabularyId = $VocabId
                displayName = $DisplayName
                name = $Prefix
                groupName = $GroupName
                isVisible = 'true'
                dataType = $DataType
                description = $Description
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
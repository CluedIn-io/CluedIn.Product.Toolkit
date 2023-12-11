function Enable-CluedInVocabulary {
    <#
        .SYNOPSIS
        GraphQL Query: Activates a Vocabulary

        .DESCRIPTION
        GraphQL Query: Activates a Vocabulary

        .EXAMPLE
        PS> Enable-CluedInVocabulary -id '6c640726-78d4-4c5c-9ad6-016bf844fd59'

        This will activate the vocabulary
    #>

    [CmdletBinding()]
    param(
        [guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'activateVocabulary'

    $query = @{
        variables = @{
            vocabularyId = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Set-CluedInVocabularyKeyMapping {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the vocaulary key mapping

        .DESCRIPTION
        GraphQL Query: Sets the vocaulary key mapping

        .EXAMPLE
        PS> Set-CluedInVocabularyKeyMapping -Source 'guid' -Destination 'guid'

        Updates the source vocabulary key and maps it to the destination vocabulary key.
    #>

    [CmdletBinding()]
    param(
        [guid]$Source,
        [guid]$Destination
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'mapToVocabularyKey'

    $query = @{
        variables = @{
            vocabularyKeyId = $Source
            mapToVocabularyKeyId = $Destination
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
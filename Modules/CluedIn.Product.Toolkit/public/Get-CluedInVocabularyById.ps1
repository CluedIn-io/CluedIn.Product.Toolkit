function Get-CluedInVocabularyById {
    <#
        .SYNOPSIS
        GraphQL Query: Gets all vocabularies

        .DESCRIPTION
        GraphQL Query: Gets all vocabularies

        .EXAMPLE
        PS> Get-CluedInVocabularyById
    #>

    [CmdletBinding()]
    param(
        [guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getVocabulary'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
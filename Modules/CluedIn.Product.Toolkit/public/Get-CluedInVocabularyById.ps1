function Get-CluedInVocabularyById {
    <#
        .SYNOPSIS
        GraphQL Query: Gets all vocabularies

        .DESCRIPTION
        GraphQL Query: Gets all vocabularies

        .PARAMETER Id
        To get detailed configuration of a vocabulary, you must specify the Id.

        .EXAMPLE
        PS> Get-CluedInVocabularyById -Id 477b5b16-ef7f-41b8-8ba3-4c027a65a3d3
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id
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
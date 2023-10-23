function Get-CluedInVocabularyKey {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all Voculatuary Keys

        .DESCRIPTION
        GraphQL Query: Returns all Voculatuary Keys

        .EXAMPLE
        PS> Get-CluedInVocabularyKey -Id 10

        This will query will return Vocabulary Key with id '10' for the connected CluedIn Organisation

        .EXAMPLE
        PS> Get-CluedInVocabularyKey

        This will query will return all Vocabulary Keys for the connected CluedIn Organisation
    #>

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Id')][guid]$Id,
        [Parameter(ParameterSetName = 'Search')][string]$Search
    )

    switch ($PsCmdlet.ParameterSetName) {
        'Id' {
            $queryContent = Get-CluedInGQLQuery -OperationName 'getVocabularyKeysFromVocabularyId'
            $variables = @{
                id = $Id
                searchName = $null
                dataType = $null
                classification = $null
                filterIsObsolete = 'All'
            }
        }
        'Search' {
            $queryContent = Get-CluedInGQLQuery -OperationName 'getVocabularyKey'
            $variables = @{
                key = $Search
            }
        }
    }

    $query = @{
        variables = $variables
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
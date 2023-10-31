function Get-CluedInVocabularyKey {
    <#
        .SYNOPSIS
        GraphQL Query: Returns detailed information about Vocabulary Keys

        .DESCRIPTION
        GraphQL Query: Returns detailed information about Vocabulary Keys

        .PARAMETER Id
        Returns very detailed information about a specified Vocabulary Key.

        .PARAMETER Search
        Returns basic information on the specified value. If nothing is specified, it will return all keys.

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
        [Parameter(ParameterSetName = 'Search')][string]$Search = "",
        [Parameter(ParameterSetName = 'All')][switch]$All
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
        'All' {
            $queryContent = Get-CluedInGQLQuery -OperationName 'getAllVocabularyKeys'
            $variables = @{
                searchName = $null
                pageNumber = 1
                pageSize = 20
                dataType = $null
                classification = $null
                connectorId = $null
                filterTypes = $null
                filterHasNoSource = $null
                filterIsObsolete = 'All'
            }
        }
    }

    $query = @{
        variables = $variables
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
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

        This will query will return Vocabulary Key with id '10' for the connected CluedIn Organization

        .EXAMPLE
        PS> Get-CluedInVocabularyKey

        This will query will return all Vocabulary Keys for the connected CluedIn Organization
    #>

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Id')][guid]$Id,
        [Parameter(ParameterSetName = 'Search')][string]$Search = "",
        [Parameter(ParameterSetName = 'All')][switch]$All
    )

    function SearchAll($searchName = $null) {
        # Null is all results.
        Write-Verbose "Searching for '$searchName'"
        $script:queryContent = Get-CluedInGQLQuery -OperationName 'getAllVocabularyKeys'
        $script:variables = @{
            searchName = $searchName
            pageNumber = 1
            pageSize = 20
            dataType = $null
            classification = $null
            connectorId = $null
            filterTypes = $null
            filterHasNoSource = $null
            filterIsObsolete = 'All'
        }

        return GetResult
    }

    function SearchSensitive() {
        # Case sensitive search
        $script:queryContent = Get-CluedInGQLQuery -OperationName 'getVocabularyKey'
        $script:variables = @{
            key = $Search
        }

        return GetResult
    }

    function GetResult() {
        $query = @{
            variables = $variables
            query = $queryContent
        }

        return Invoke-CluedInGraphQL -Query $query
    }

    switch ($PsCmdlet.ParameterSetName) {
        'Id' {
            $script:queryContent = Get-CluedInGQLQuery -OperationName 'getVocabularyKeysFromVocabularyId'
            $variables = @{
                id = $Id
                searchName = $null
                dataType = $null
                classification = $null
                skipFilterVisibility = $true
                filterIsObsolete = 'All'
            }

            $result = GetResult
        }
        'Search' {
            $result = SearchSensitive
            if (!$result.data.management.vocabularyPerKey.key) {
                Write-Verbose "Cannot find key. Searching without case sensitivity"
                $secondResult = SearchAll($Search) # Will not find key if IsVisible is set to false
                if ($secondResult.data.management.vocabularyKeys.total -eq 1) {
                    $result.data.management.vocabularyPerKey = $secondResult.data.management.vocabularyKeys.data[0]
                }
            }
        }
        'All' { $result = SearchAll }
    }

    return $result
}
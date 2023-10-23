function Get-CluedInVocabulary {
    <#
        .SYNOPSIS
        GraphQL Query: Gets all vocabularies

        .DESCRIPTION
        GraphQL Query: Gets all vocabularies

        .PARAMETER Search

        .PARAMETER IncludeCore
        By default, all CluedIn base vocabularies will be filtered out. If this is set to $true
        it will return all results without any filtering

        .EXAMPLE
        PS> Get-CluedInVocabulary
    #>

    [CmdletBinding()]
    param(
        [string]$Search = "",
        [switch]$IncludeCore
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAllVocabularies'

    $query = @{
        variables =@{
            searchName = $Search
            pageNumber = 1
            pageSize = 20
            entityType = $null
            connectorId = $null
            isActive = $null
            filterTypes = $null
            filterHasNoSource = $null
        }
        query = $queryContent
    }

    $result = Invoke-CluedInGraphQL -Query $query

    if (!$IncludeCore) {
        $result.data.management.vocabularies.data = $result.data.management.vocabularies.data |
            Where-Object {$_.isCluedInCore -eq $false}
        $result.data.management.vocabularies.total = $result.data.management.vocabularies.data.count
    }

    return $result
}
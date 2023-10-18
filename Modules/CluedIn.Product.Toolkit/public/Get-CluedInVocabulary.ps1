function Get-CluedInVocabulary {
    <#
        .SYNOPSIS
        GraphQL Query: Gets all vocabularies

        .DESCRIPTION
        GraphQL Query: Gets all vocabularies

        .EXAMPLE
        PS> Get-CluedInVocabulary
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAllVocabularies'

    $query = @{
        variables =@{
            searchName = $null
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

    return Invoke-CluedInGraphQL -Query $query
}
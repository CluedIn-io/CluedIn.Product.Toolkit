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

    $result = Invoke-CluedInGraphQL -Query $query
    $total = $result.data.management.vocabularies.total
    
    while ($true) {
        $query['variables']['pageNumber']++
        $nextPage = Invoke-CluedInGraphQL -Query $query
        $result.data.management.vocabularies.data += $nextPage.data.management.vocabularies.data
        if ($result.data.management.vocabularies.data.count -ge $total) { break }
    }

    # This is cleanup from client side. Our GraphQL may not support filtering at runtime
    # Something to look into?
    $result.data.management.vocabularies.data = $result.data.management.vocabularies.data | 
        Where-Object {$_.isCluedInCore -eq $false}
    $result.data.management.vocabularies.total = $result.data.management.vocabularies.data.count
    #
    
    return $result
}
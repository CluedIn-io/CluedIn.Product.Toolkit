function Get-CluedInGlossaryTerms {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all Glossaries

        .DESCRIPTION
        GraphQL Query: Returns all Glossaries

        .EXAMPLE
        PS> Get-CluedInGlossary
    #>

    [CmdletBinding()]
    param (
        [string]$Search = ""
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getGlossaryTerms'

    $query = @{
        variable = @{
            searchName = $Search
            pageNumber = 1
            pageSize = 20
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Get-CluedInGlossaryTerms {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all Glossaries Terms

        .DESCRIPTION
        GraphQL Query: Returns all Glossaries Terms

        .PARAMETER Search
        If specified, will return a narrowed down results. By default, it will return everything

        .EXAMPLE
        PS> Get-CluedInGlossaryTerms

        .EXAMPLE
        PS> Get-CluedInGlossaryTerms -Search "Sample Term"
    #>

    [CmdletBinding()]
    param (
        [guid]$GlossaryId
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getGlossaryTerms'

    $query = @{
        variables = @{
            categoryId = $GlossaryId
            pageNumber = 1
            pageSize = 20
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
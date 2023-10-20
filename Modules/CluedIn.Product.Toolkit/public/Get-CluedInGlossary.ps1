function Get-CluedInGlossary {
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

    $queryContent = Get-CluedInGQLQuery -OperationName 'getGlossaryCategory'

    $query = @{
        variable = @{
            name = $Search
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Get-CluedInGlossary {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all Glossaries

        .DESCRIPTION
        GraphQL Query: Returns all Glossaries

        .PARAMETER Search
        Returns narrowed results when specify a Search parameter value. If not used, it will return everything
        Is not a hard match

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
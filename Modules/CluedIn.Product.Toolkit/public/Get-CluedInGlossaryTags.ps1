function Get-CluedInGlossaryTags {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all glossary tags

        .DESCRIPTION
        GraphQL Query: Returns all glossary tags

        .EXAMPLE
        PS> Get-CluedInGlossaryTags

        This will return back all Glossary Term Tags
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAllTerms'

    $query = @{
        variables = @{}
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
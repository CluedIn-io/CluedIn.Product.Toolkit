function Get-CluedInGlossary {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all Glossaries or if Id is specified, just the one glossary.

        .DESCRIPTION
        GraphQL Query: Returns all Glossaries or if Id is specified, just the one glossary.

        .PARAMETER Id
        Returns just the glossary information if found.

        .EXAMPLE
        PS> Get-CluedInGlossary
        PS> Get-CluedInGlossary -Id b5ca9f3c-885b-4c50-88c4-45cd676c2b50
    #>

    [CmdletBinding()]
    param (
        [guid]$Id
    )

    if ($Id) { $opName = 'getGlossaryCategoryById' }
    else { $opName = 'getGlossaryCategory' }

    $queryContent = Get-CluedInGQLQuery -OperationName $opName

    $query = @{
        variables = @{}
        query = $queryContent
    }

    if ($Id) { $query.variables.id = $Id }

    return Invoke-CluedInGraphQL -Query $query
}
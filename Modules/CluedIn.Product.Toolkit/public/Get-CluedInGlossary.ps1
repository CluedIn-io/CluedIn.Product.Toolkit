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
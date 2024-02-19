function Get-CluedInGlossaryTerm {
    <#
        .SYNOPSIS
        GraphQL Query: Returns Glossarie Term configuration

        .DESCRIPTION
        GraphQL Query: Returns Glossarie Term configuration

        .PARAMETER Id
        This is the Id of the term itself.

        .EXAMPLE
        PS> Get-CluedInGlossaryTerm

        .EXAMPLE
        PS> Get-CluedInGlossaryTerm -Id 7d23fe68-ae2f-4a2a-a329-99d118389f4e
    #>

    [CmdletBinding()]
    param (
        [guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getGlossaryTerm'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
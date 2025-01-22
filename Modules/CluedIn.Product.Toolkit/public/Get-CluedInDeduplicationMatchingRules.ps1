function Get-CluedInDeduplicationMatchingRules {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all deduplication projects

        .DESCRIPTION
        GraphQL Query: Returns all deduplication projects

        .PARAMETER Id
        Mandatory parameter that must be specified to retrieve the data of a given Deduplication Project Matching Rules

        .EXAMPLE
        PS> Get-CluedInDeduplicationMatchingRules

        This will return back all Deduplication Projects
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getDeduplicationMatchingRules'

    $query = @{
        variables = @{
            id = $Id
            pageNumber = 1
            itemsPerPage = 20
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Get-CluedInDeduplicationProject {
    <#
        .SYNOPSIS
        GraphQL Query: Returns the Deduplication Project for the specified id

        .DESCRIPTION
        GraphQL Query: Returns the Deduplication Project for the specified id

        .PARAMETER Id
        Mandatory parameter that must be specified to retrieve the data of a given Deduplication Project

        .EXAMPLE
        PS> Get-CluedInDeduplicationProject

        This will return the Deduplication Project for the specified id
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getDeduplicationProject'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
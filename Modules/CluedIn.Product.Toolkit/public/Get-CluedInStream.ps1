function Get-CluedInStream {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about streams

        .DESCRIPTION
        GraphQL Query: Returns information about streams

        .PARAMETER Id
        guid of the stream you want to get information on

        .EXAMPLE
        PS> Get-CluedInStream -Id 'd04f41f8-5063-49dc-a30e-268439168437'
    #>

    [CmdletBinding()]
    param(
        [guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getStream'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
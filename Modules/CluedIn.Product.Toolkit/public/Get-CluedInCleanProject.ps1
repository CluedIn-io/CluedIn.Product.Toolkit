function Get-CluedInCleanProject {
    <#
        .SYNOPSIS
        GraphQL Query: Returns detailed config of a given clean project

        .DESCRIPTION
        GraphQL Query: Returns detailed config of a given clean project

        .PARAMETER Id
        This is the Id of a given clean project

        .EXAMPLE
        PS> Get-CluedInCleanProject -Id a7f0ef75-6891-4767-b360-963159aa92f5

        This will return back details information about the clean project id above
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'cleanProjectDetail'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
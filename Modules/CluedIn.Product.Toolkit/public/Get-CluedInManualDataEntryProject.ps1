function Get-CluedInManualDataEntryProject {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about manual data entry project

        .DESCRIPTION
        GraphQL Query: Returns information about manual data entry project

        .PARAMETER Id
        Guid of the manual data entry project you want to get information on

        .EXAMPLE
        PS> Get-CluedInManualDataEntryProject -Id "guid"
    #>

    [CmdletBinding()]
    param(
        [guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getManualDataEntryProject'

    $query = @{
        variables = @{
            id=$Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
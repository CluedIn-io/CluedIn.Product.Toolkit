function Get-CluedInDataSet {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all datasets or a singular dataset if an id is provided

        .DESCRIPTION
        GraphQL Query: Returns all datasets or a singular dataset if an id is provided

        .EXAMPLE
        PS> Get-CluedInDataSet -Id 10
        
        This will query will return dataset id '10' for the connected CluedIn Organisation

        .EXAMPLE
        PS> Get-CluedInDataSet
        
        This will query will return all datasets for the connected CluedIn Organisation
    #>

    [CmdletBinding()]
    param(
        [guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getDataSetById'

    $query = @{
        variables = @{
            id = $Id
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
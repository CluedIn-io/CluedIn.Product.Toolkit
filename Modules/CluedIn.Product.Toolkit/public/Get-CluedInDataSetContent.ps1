function Get-CluedInDataSetContent {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all content for a specific dataset

        .DESCRIPTION
        GraphQL Query: Returns all content for a specific dataset

        .EXAMPLE
        PS> Get-CluedInDataSetContent -Id '97D22210-F18C-4378-BF52-D79D354275E4'

        This will return dataset content for the dataSetId '97D22210-F18C-4378-BF52-D79D354275E4' for the connected CluedIn Organisation
    #>

    [CmdletBinding()]
    param(
        [guid]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getDataSetContent'

    $query = @{
        variables = @{
            dataSetId = $Id
            page = 0
            pageSize = 10
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
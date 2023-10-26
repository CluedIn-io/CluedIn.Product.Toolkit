function Get-CluedInMe {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about the authenticated user

        .DESCRIPTION
        GraphQL Query: Returns information about the authenticated user

        .EXAMPLE
        PS> Get-CluedInMe
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'me'
    $query = @{
        variables = @{}
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
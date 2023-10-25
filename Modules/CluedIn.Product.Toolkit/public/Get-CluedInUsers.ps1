function Get-CluedInUsers {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all users setup on the system

        .DESCRIPTION
        GraphQL Query: Returns all users setup on the system

        .EXAMPLE
        PS> Get-CluedInUsers

        Returns all users
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getUsers'
    $query = @{
        variables = @{}
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
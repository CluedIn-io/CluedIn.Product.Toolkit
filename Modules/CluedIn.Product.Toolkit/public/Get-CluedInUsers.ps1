function Get-CluedInUsers {
    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getUsers'
    $query = @{ query = $queryContent }

    return Invoke-CluedInGraphQL -Query $query
}
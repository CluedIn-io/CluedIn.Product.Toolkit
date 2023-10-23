function Get-CluedInMe {
    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'me'
    $query = @{
        variables = @{}
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
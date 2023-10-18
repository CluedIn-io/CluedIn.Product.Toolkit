function Get-CluedInMe {
    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'me'

    $query = @{ query = $queryContent }

    return Invoke-CluedInGraphQL -Query $query
}
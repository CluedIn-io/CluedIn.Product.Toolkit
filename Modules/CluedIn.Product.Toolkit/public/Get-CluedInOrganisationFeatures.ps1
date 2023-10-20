function Get-CluedInOrganisationFeatures {
    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getOrganizationFeatures'
    $query = @{ query = $queryContent }

    return Invoke-CluedInGraphQL -Query $query
}
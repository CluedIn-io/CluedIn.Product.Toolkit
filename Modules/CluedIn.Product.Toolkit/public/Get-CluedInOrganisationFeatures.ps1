function Get-CluedInOrganisationFeatures {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about the connected Organisation Features

        .DESCRIPTION
        GraphQL Query: Returns information about the connected Organisation Features

        .EXAMPLE
        PS> Get-CluedInOrganisationFeatures
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getOrganizationFeatures'
    $query = @{
        variables = @{}
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
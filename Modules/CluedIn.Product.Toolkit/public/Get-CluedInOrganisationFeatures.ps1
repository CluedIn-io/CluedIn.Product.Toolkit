function Get-CluedInOrganizationFeatures {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about the connected Organization Features

        .DESCRIPTION
        GraphQL Query: Returns information about the connected Organization Features

        .EXAMPLE
        PS> Get-CluedInOrganizationFeatures
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
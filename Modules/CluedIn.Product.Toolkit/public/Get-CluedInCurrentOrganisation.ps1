function Get-CluedInCurrentOrganization {
    <#
        .SYNOPSIS
        GraphQL Query: Gets the Current Organization metadata based on endpoint provided.

        .DESCRIPTION
        GraphQL Query: Gets the Current Organization metadata based on endpoint provided.

        .EXAMPLE
        PS> Get-CluedInCurrentOrganization
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getCurrentOrg'
    $query = @{
        variables = @{}
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
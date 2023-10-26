function Get-CluedInCurrentOrganisation {
    <#
        .SYNOPSIS
        GraphQL Query: Gets the Current Organisation metadata based on endpoint provided.

        .DESCRIPTION
        GraphQL Query: Gets the Current Organisation metadata based on endpoint provided.

        .EXAMPLE
        PS> Get-CluedInCurrentOrganisation
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
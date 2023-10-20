function Get-CluedInCurrentOrganisation {
    <#
        .SYNOPSIS
        GraphQL Query: Gets the Current Organisation metadata based on endpoint provided.

        .DESCRIPTION
        GraphQL Query: Gets the Current Organisation metadata based on endpoint provided.

        .EXAMPLE
        PS> Get-CluedInCurrentOrganisation

        This will query the endpoint with a GraphQL body and return a powershell object which contains data you can use.
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getCurrentOrg'
    $query = @{ query = $queryContent }

    return Invoke-CluedInGraphQL -Query $query
}
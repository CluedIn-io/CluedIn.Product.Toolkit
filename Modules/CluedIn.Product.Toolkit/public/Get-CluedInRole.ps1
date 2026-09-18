function Get-CluedInRole {
    <#
        .SYNOPSIS
        GraphQL Query: Returns a single role along with all of its claims

        .DESCRIPTION
        GraphQL Query: Returns a single role along with all of its claims.

        Roles are looked up by name and not by id. CluedIn only hydrates the claims of a role when it's
        queried by name, so Get-CluedInRoles should be used first to resolve an id to a name if required.

        .PARAMETER Name
        The name of the role to return. This is a hard match and is how CluedIn itself keys a role,
        ie. 'DataSteward'.

        .EXAMPLE
        PS> Get-CluedInRole -Name 'DataSteward'

        Will return the DataSteward role along with every claim and the level it's held at
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getRole'

    $query = @{
        variables = @{
            roleName = $Name
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

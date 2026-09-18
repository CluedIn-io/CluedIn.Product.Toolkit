function New-CluedInRole {
    <#
        .SYNOPSIS
        GraphQL Mutation: Creates a new role

        .DESCRIPTION
        GraphQL Mutation: Creates a new role.

        A role is created empty. The response lists every claim the environment defines with a value of
        'None', so the role grants nothing until those levels are set with Set-CluedInRole. The returned
        claims are what should be used as the baseline for that call.

        .PARAMETER Name
        The name of the role to create, ie. 'DataSteward'.

        CluedIn keys role membership on the name and not the id, so a name containing whitespace produces
        a role that users can't be assigned to.

        .PARAMETER Description
        The description shown beside the role in the admin section.

        .EXAMPLE
        PS> New-CluedInRole -Name 'DataSteward' -Description 'Role dedicated to cleaning data'

        Will create the role with every claim set to 'None'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Description = ''
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createRole'

    $query = @{
        variables = @{
            role = @{
                name = $Name
                description = $Description
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

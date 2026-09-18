function Set-CluedInRole {
    <#
        .SYNOPSIS
        GraphQL Mutation: Sets a role along with the access level of each of its claims

        .DESCRIPTION
        GraphQL Mutation: Sets a role along with the access level of each of its claims.

        CluedIn writes what it's sent, so the complete claim list has to be passed on every call. A claim
        that's left out of the payload is one the environment is free to treat as not granted, which is why
        Import-Roles merges over the claims returned by New-CluedInRole rather than sending a handful.

        The name and description are also written as sent, so pass the current values through unless the
        role is meant to be renamed.

        .PARAMETER Id
        The id of the role to save

        .PARAMETER Name
        The name of the role. This is written as sent.

        .PARAMETER Description
        The description of the role. This is written as sent.

        .PARAMETER Claims
        The complete list of claims to write. Each entry needs a 'name' and a 'value', which is the format
        both New-CluedInRole and Get-CluedInRole return them in.

        .EXAMPLE
        PS> Set-CluedInRole -Id $id -Name 'DataSteward' -Claims $claims

        Will save the role with the passed in claims
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [string]$Description = '',
        [array]$Claims
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveRole'

    $query = @{
        variables = @{
            role = @{
                id = $Id
                name = $Name
                description = $Description
                claims = @($Claims | ForEach-Object { @{ name = $_.name; value = $_.value } })
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

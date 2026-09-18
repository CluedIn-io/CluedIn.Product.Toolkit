function Get-CluedInRoles {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all roles setup on the system

        .DESCRIPTION
        GraphQL Query: Returns all roles setup on the system.

        Returned data is less detailed than using Get-CluedInRole. Claims are not included as part of this
        query, so use the returned name against Get-CluedInRole for the full role configuration.

        .PARAMETER Search
        If you want to narrow the results, specify a string here. By default, all roles will be returned.
        It's not a hard match.

        .EXAMPLE
        PS> Get-CluedInRoles

        Will return all roles

        .EXAMPLE
        PS> Get-CluedInRoles -Search 'DataSteward'

        Will return all roles that contain 'DataSteward' in the name
    #>

    [CmdletBinding()]
    param(
        [string]$Search = ""
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getRoles'

    $query = @{
        variables = @{
            searchName = $Search
            pageNumber = 1
            itemsPerPage = 20
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

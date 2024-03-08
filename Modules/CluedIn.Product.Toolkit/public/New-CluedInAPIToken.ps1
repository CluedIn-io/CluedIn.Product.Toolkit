function New-CluedInAPIToken {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new API Token that can be used to connect to the Organization

        .DESCRIPTION
        GraphQL Query: Creates a new API Token that can be used to connect to the Organization

        .EXAMPLE
        PS> New-CluedInAPIToken -Name $guid -ExpiredInHours 24

        Returns a new API Token that is valid for 24 hours. It's only limited scope and not full admin permission.
    #>

    [CmdletBinding()]
    param(
        [guid]$Name,
        [int]$ExpiredInHours = 732 # 30 days
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createToken'

    $query = @{
        variables =@{
            name = $Name
            expiredInHours = $ExpiredInHours
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
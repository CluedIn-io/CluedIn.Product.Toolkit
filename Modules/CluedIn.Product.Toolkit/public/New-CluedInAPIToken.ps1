function New-CluedInAPIToken {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new API Token

        .DESCRIPTION
        GraphQL Query: Creates a new API Token

        .EXAMPLE
        PS> New-CluedInAPIToken
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
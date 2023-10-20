function Get-CluedInAPITokens {
    <#
        .SYNOPSIS
        GraphQL Query: Gets a list of all API Tokens for logged in user

        .DESCRIPTION
        GraphQL Query: Gets a list of all API Tokens for logged in user

        .EXAMPLE
        PS> Get-CluedInAPITokens
    #>

    [CmdletBinding()]
    param()

    $queryContent = Get-CluedInGQLQuery -OperationName 'getApiTokens'
    $query = @{ query = $queryContent }

    return Invoke-CluedInGraphQL -Query $query
}
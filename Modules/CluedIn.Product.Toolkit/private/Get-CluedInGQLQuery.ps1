function Get-CluedInGQLQuery {
    <#
        .SYNOPSIS
        Grabs the GraphQL query from store based on a few predetermined attributes

        .DESCRIPTION
        Grabs the GraphQL query from store based on a few predetermined attributes

        .PARAMETER OperationName
        This must match a the file name in ../GraphQL without .gql added

        .EXAMPLE
        PS> Get-CluedInGQLQuery -OperationName 'getCurrentOrg'
    #>

    [CmdletBinding()]
    param([string]$OperationName)

    $path = "$PSScriptRoot/../GraphQL/$operationName.gql"

    if (!(Test-Path -Path $path -PathType Leaf)) {
        throw "Could not find '$operationName.gql' in the GraphQL folder"
    }

    return Get-Content -Path $path -Raw
}
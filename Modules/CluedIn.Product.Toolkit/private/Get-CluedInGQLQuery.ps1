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

    if (!${env:CLUEDIN_CURRENTVERSION}) {
        throw "The env 'CLUEDIN_CURRENTVERSION' is not set. Please run Connect-CluedInOrganisation"
    }

    return Get-Content -Path "$PSScriptRoot/../GraphQL/${env:CLUEDIN_CURRENTVERSION}/$operationName.gql" -Raw
}
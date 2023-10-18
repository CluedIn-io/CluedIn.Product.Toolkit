function Get-CluedInGQLQuery {
    [CmdletBinding()]
    param([string]$OperationName)
    
    if (!${env:CLUEDIN_CURRENTVERSION}) {
        throw "The env 'CLUEDIN_CURRENTVERSION' is not set. Please run Connect-CluedInOrganisation"
    }

    return Get-Content -Path "$PSScriptRoot/../GraphQL/${env:CLUEDIN_CURRENTVERSION}/$operationName.gql" -Raw
}
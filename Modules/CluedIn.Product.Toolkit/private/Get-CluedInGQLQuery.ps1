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

    $path = "$PSScriptRoot/../GraphQL/${env:CLUEDIN_CURRENTVERSION}/$operationName.gql"

    if (!(Test-Path -Path $path -PathType Leaf)) {
        $graphQLFolder = "$PSScriptRoot/../GraphQL"
        $folderVersion = (Get-ChildItem -Path $graphQLFolder).name | Sort-Object -Descending
        foreach ($version in $folderVersion) {
            Write-Debug "Working on $version"
            if ($version -eq ${env:CLUEDIN_CURRENTVERSION}) { Write-Debug "Skipping"; continue }
            if ([version]$version -gt [version]${env:CLUEDIN_CURRENTVERSION}) { Write-Debug "Skipping"; continue }

            $testPath = "$PSScriptRoot/../GraphQL/$version/$operationName.gql"
            if (Test-Path -Path $testPath) {
                $path = $testPath
                Write-Verbose "Using $version"; break
            }
        }
        if (!$path) { throw "Could not find '$operationName.gql' in any of the GraphQL folders" }
    }

    return Get-Content -Path $path -Raw
}
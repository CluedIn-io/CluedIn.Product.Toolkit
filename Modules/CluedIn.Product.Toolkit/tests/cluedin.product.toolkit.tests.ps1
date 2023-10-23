BeforeDiscovery {
    $GraphQLFunctions = Get-ChildItem -Path "$(Split-Path -Parent $PSScriptRoot)/GraphQL" -Filter *.ps1
}

BeforeAll {
    $moduleDirectory = Split-Path -Parent $PSScriptRoot # Returns root module folder
    $moduleName = 'CluedIn.Product.Toolkit'
}

Describe "Unit Testing" {
    Context "General" {
        It "<moduleName>.psm1 exists" {
            $path = Join-Path -Path $moduleDirectory -ChildPath "$moduleName.psm1"
            $path | Should -Exist
        }

        It "<moduleName>.psd exists" {
            $path = Join-Path -Path $moduleDirectory -ChildPath "$moduleName.psd"
            $path | Should -Exist
        }

        It "has private functions" {
            $privateFunc = Join-Path -Path $moduleDirectory -ChildPath 'private'
            $funcs = Get-ChildItem -Path $privateFunc -Filter *.ps1
            $funcs.count | Should -BeGreaterThan 0
        }

        It "has public functions" {
            $publicFunc = Join-Path -Path $moduleDirectory -ChildPath 'public'
            $funcs = Get-ChildItem -Path $publicFunc -Filter *.ps1
            $funcs.count | Should -BeGreaterThan 0
        }

        It "GraphQL Folder exists" {
            $graphqlPath = Join-Path -Path $moduleDirectory -ChildPath 'GraphQL'
            Test-Path -Path $graphqlPath -PathType Container | Should -BeTrue
        }

        It "GraphQL\Queries Folder exists" {
            $graphqlPath = Join-Path -Path $moduleDirectory -ChildPath 'GraphQL\Queries'
            Test-Path -Path $graphqlPath -PathType Container | Should -BeTrue
        }
    }

    Context "Core Functions" {
        BeforeAll { Import-Module $moduleDirectory }

        Context "General" {
            It "Core Function: <_> exists" -ForEach @(
                'Connect-CluedInOrganisation'
                'Out-JsonFile'
                'Invoke-CluedInGraphQL'
            ) {
                Get-Command -Name $_ -Module $moduleName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It "Variables key exists" {
                throw
            }
        }

        Context "GraphQL" {
            It "<_.basename> matches cmdlet name" -forEach $GraphQLFunctions {
                Get-Command -Name $_.basename -Module $moduleName -ErrorAction SilentlyContinue |
                    Should -Not -BeNullOrEmpty
            }
        }
    }
}
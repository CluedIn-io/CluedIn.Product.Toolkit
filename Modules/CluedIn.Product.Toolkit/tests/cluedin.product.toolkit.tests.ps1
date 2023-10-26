BeforeDiscovery {
    $publicGetFunctions = Get-ChildItem -Path "$(Split-Path -Parent $PSScriptRoot)/public" -Filter "Get-*.ps1"
}

BeforeAll {
    $moduleDirectory = Split-Path -Parent $PSScriptRoot # Returns root module folder
    $publicFuncPath = Join-Path -Path $moduleDirectory -ChildPath 'public'
    $moduleName = 'CluedIn.Product.Toolkit'
}

Describe "Unit Testing" {
    Context "General" {
        It "<moduleName>.psm1 exists" {
            $path = Join-Path -Path $moduleDirectory -ChildPath "$moduleName.psm1"
            $path | Should -Exist
        }

        It "<moduleName>.psd1 exists" {
            $path = Join-Path -Path $moduleDirectory -ChildPath "$moduleName.psd1"
            $path | Should -Exist
        }

        It "has private functions" {
            $privateFunc = Join-Path -Path $moduleDirectory -ChildPath 'private'
            $funcs = Get-ChildItem -Path $privateFunc -Filter *.ps1
            $funcs.count | Should -BeGreaterThan 0
        }

        It "has public functions" {
            $funcs = Get-ChildItem -Path $publicFuncPath -Filter *.ps1
            $funcs.count | Should -BeGreaterThan 0
        }

        It "GraphQL Folder exists" {
            $graphqlPath = Join-Path -Path $moduleDirectory -ChildPath 'GraphQL'
            Test-Path -Path $graphqlPath -PathType Container | Should -BeTrue
        }
    }

    Context "Core Functions" {
        BeforeAll { Import-Module $moduleDirectory }

        Context "General" {
            It "Core Function: <_> exists" -ForEach @(
                'Connect-CluedInOrganisation'
                'Out-JsonFile'
            ) {
                Get-Command -Name $_ -Module $moduleName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }

            It "<_.basename> Variables key exists" -foreach $publicGetFunctions {
                $item = Get-Content $_.fullname
                $regex = 'variables? = @{'
                $result = $item | Select-String -Pattern $regex
                $result.matches.Success | Should -BeTrue
            }
        }
    }
}
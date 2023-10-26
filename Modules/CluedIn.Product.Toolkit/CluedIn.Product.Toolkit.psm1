<#
    .DESCRIPTION
    All ps1 files within this folder are a separate function. They all get dot sourced upon import of the module.
#>

Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" -Exclude "*.tests.ps1" -Recurse | ForEach-Object { . $_ }
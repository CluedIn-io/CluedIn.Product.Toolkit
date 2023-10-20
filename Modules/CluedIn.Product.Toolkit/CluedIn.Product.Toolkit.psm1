<#
    .DESCRIPTION
    All ps1 files within this folder are a separate function. They all get dot sourced upon import of the module.
#>

Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" -Exclude "*.tests.ps1" -Recurse | ForEach-Object { . $_ }
Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath public) -Filter *.ps1 |
    ForEach-Object { Export-ModuleMember -Function $_.Basename }
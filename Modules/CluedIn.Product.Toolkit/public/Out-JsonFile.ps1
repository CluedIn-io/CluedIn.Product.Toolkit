function Out-JsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][PSCustomObject]$Object,
        [string]$Path,
        [string]$Name
    )

    if (!$Path) {$Path = $pwd}
    $exportPath = Join-Path -Path $Path -ChildPath ('{0}.json' -f $Name)
    $Object | ConvertTo-Json -Depth 99 | Out-File -FilePath $exportPath

    Write-Verbose "File exported '$exportPath'"
}
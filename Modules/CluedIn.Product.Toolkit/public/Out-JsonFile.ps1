function Out-JsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][PSCustomObject]$Object,
        [string]$Path = $pwd,
        [string]$Name
    )

    $exportPath = Join-Path -Path $Path -ChildPath ('{0}.json' -f $Name)
    $Object | ConvertTo-Json -Depth 20 | Out-File -FilePath $exportPath

    Write-Verbose "File exported '$exportPath'"
}
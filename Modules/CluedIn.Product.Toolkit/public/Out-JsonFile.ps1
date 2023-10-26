function Out-JsonFile {
    <#
        .SYNOPSIS
        Wrapper function to streamline outputting CluedIn results as JSON to disk

        .DESCRIPTION
        Wrapper function to streamline outputting CluedIn results as JSON to disk

        .PARAMETER Object
        Because all Get-Functions for the CluedIn Toolkit as PSCustomObjects, it expects the passed in object to be exactly that.

        It will convert this to JSON and then write to disk.

        .PARAMETER Path
        This is the location where the json file will be written to

        .PARAMETER Name
        This is the name of the file without `.json`

        .EXAMPLE
        PS> Out-JsonFile -Object $vocabularyKeyObject -Name 'vocaularyKey-1' -Path /path/to/backup/folder
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][PSCustomObject]$Object,
        [string]$Path = $pwd,
        [Parameter(Mandatory)][string]$Name
    )

    $exportPath = Join-Path -Path $Path -ChildPath ('{0}.json' -f $Name)
    $Object | ConvertTo-Json -Depth 20 | Out-File -FilePath $exportPath

    Write-Verbose "File exported '$exportPath'"
}
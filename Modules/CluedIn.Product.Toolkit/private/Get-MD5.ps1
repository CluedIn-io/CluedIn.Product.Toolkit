function Get-MD5 {
    param(
        [string]$String
    )
    $stringAsStream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($stringAsStream)
    $writer.write($String)
    $writer.Flush()
    $stringAsStream.Position = 0
    
    return Get-FileHash -InputStream $stringAsStream -Algorithm MD5
}
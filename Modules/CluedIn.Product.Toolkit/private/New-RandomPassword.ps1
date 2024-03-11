function New-RandomPassword {
    param([switch]$SecureString)
    function randLetter{'a','b','c','d','e','f','g','h' | Get-Random}
    $plainValue = (openssl rand -base64 30).Replace('/', (randLetter)).Replace('+', (randLetter))
    return (!$SecureString ? $plainValue : (ConvertTo-SecureString -String $plainValue -AsPlainText))
}
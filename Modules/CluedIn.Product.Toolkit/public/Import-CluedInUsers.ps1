function Import-CluedInUsers {
    <#
        .SYNOPSIS
        Creates user(s) in CluedIn once authenticated

        .DESCRIPTION
        Creates a user or multiple users within CluedIn. It does not modify role or assignments, just creates the account

        .PARAMETER BaseURL
        This is the FQDN without the cluedin subdomain prepended. Do not include http(s)://

        .PARAMETER CsvPath
        To batch create users, you can specify a csv file with at least `username` column. `password` column is also accepted.
        If not specified, it will randomly generate passwords for all users.

        .PARAMETER Username
        This is to be in email format. It will generate a random password if used and output on console

        .PARAMETER Organization
        This is the subdomain of the url which is followed by the BaseURL (ie. cluedin)

        .EXAMPLE
        PS> Import-CluedInUsers -BaseURL 'devcluedin.com' -Organization 'cluedin' -CsvPath /path/to/file.csv

        This will first validate the csv file exists and it will begin to process the users
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory)][string]$BaseURL,
        [parameter(Mandatory)][string]$Organization,
        [parameter(Mandatory, ParameterSetName='Batch')]
        [ValidateScript({Test-Path -Path $_ -PathType 'Leaf'})]
        [string]$CsvPath,
        [parameter(Mandatory, ParameterSetName='User')][string]$Username
    )

    function hashify($Username) {
        $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
        $utf8 = new-object -TypeName System.Text.UTF8Encoding
        $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($Username)))
        return ($hash.ToUpper() -replace '-', '')
    }

    function setupAccount($userConfig) {
        $body = @{
            username = $userConfig['username']
            password = $userConfig['password']
            applicationSubDomain = $Organization
            grant_type = 'password'
            confirmpassword = $userConfig['password']
            email = $userConfig['username']
            AllowEmailDomainSignup = 'True'
        }

        $headers = @{
            'Content-Type' = 'application/x-www-form-urlencoded'
            Authorization = "Bearer ${env:CLUEDIN_JWTOKEN}"
        }

        $NewUserUrl = "https://${Organization}.${BaseUrl}/auth/api/account/register?code=$($userConfig['hash'])"
        Try {
            Invoke-RestMethod -Method POST -Uri $NewUserUrl -Body $body -Headers $headers | Out-Null
            Write-Host "Sucessfully created account."
            Write-Host "Password: $($userConfig['password'])"
            Write-Host ""
        }
        Catch { Write-Warning "Issue with creation. Error Code: $_" }
    }

    Write-Verbose "Start of script"

    Write-Host "Connecting to Organization"
    Connect-CluedInOrganization -BaseURL $BaseURL -Organization $Organization

    Write-Host "Processing user creations now"
    $processArray = @()
    switch ($PSCmdlet.ParameterSetName) {
        'Batch' {
            $csvObject = Import-Csv -Path $CsvPath -Delimiter ','
            $csvOutputObject = @()

            if (!($csvObject | Get-Member -MemberType NoteProperty -Name 'username')) {
                throw "No username column detected. Please correct csv"
            }

            $csvObject | ForEach-Object {
                if (!$_.username) { continue }
                if ($_.username -notmatch '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$') {
                    Write-Warning "'$($_.username)' is not a valid email address. Please correct and reimport"
                    continue
                }

                $pw = ($_.password ? $_.password : (New-RandomPassword))

                $processArray += @{
                    username = ($_.username).ToLower()
                    password = $pw
                    hash = (hashify(($_.username).ToLower()))
                }

                $csvOutputObject += @{ username = $_.username; password = $pw }
            }
        }
        'User' {
            $processArray += @{
                username = $Username.ToLower()
                password = (New-RandomPassword)
                hash = (hashify($Username.ToLower()))
            }
        }
        Default { Write-Warning "Invalid Parameter Set"; return }
    }

    $processArray | ForEach-Object {
        Write-Host "Processing '$($_['username'])'"
        setupAccount($_)
    }

    if ($PSCmdlet.ParameterSetName -eq 'Batch') {
        $outputPath = Join-Path -Path (Split-Path $CsvPath) -ChildPath ('users-uploaded-{0}.csv' -f (Get-Date -Format HHmmss_ddMMyy))

        Write-Host "Output of csv with password adaptions can be found below"
        Write-Host $outputPath

        $csvOutputObject | ConvertTo-Csv | Out-File -Path $outputPath
    }

    Write-Verbose "End of script"
}
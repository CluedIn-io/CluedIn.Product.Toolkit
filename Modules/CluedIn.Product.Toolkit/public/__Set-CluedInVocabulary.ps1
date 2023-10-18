function Set-CluedInVocabulary {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a voculary

        .DESCRIPTION
        GraphQL Query: Sets a voculary

        .EXAMPLE
        PS> Set-CluedInVocabulary
    #>

    [CmdletBinding()]
    param(
        [int[]]$VocabularyId
    )

    

    $FolderPath=  "$PSScriptRoot\BackupFiles\Vocabs"   


    $tmpVCKIDS = $VCKIDS.split(",")
     [array]::Reverse($tmpVCKIDS)

    foreach ($VCKID in $tmpVCKIDS) {
    $vocbq = getVocabById -vocabId $VCKID

    $vocb = Get-CI-Data -baseURL "$_baseURL" -token $Token -GQlQuery $vocbq | ConvertFrom-Json 

    $Name = $vocb.data.management.vocabulary.vocabularyId
 
    $vocb  | ConvertTo-Json -Depth 10  | Out-File -FilePath  "$FolderPath\VOC-$Name.json"

    $VCK = GetVocabKeys -VocabId $VCKID

    $Query = Get-CI-Data -baseURL "$_baseURL" -token $Token -GQlQuery $VCK | ConvertFrom-Json 

    $Query | ConvertTo-Json -Depth 10  | Out-File -FilePath  "$FolderPath\VOCK-$Name.json"

    }
    
}
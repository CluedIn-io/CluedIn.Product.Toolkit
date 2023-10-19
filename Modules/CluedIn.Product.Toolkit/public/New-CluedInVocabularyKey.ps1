function New-CluedInVocabularyKey {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Vocabulary Key

        .DESCRIPTION
        GraphQL Query: Creates a New Vocabulary Key

        .EXAMPLE
        PS> New-CluedInVocabularyKey
    #>

    param(
        [Parameter(ParameterSetName = 'New')][string]$DisplayName, 
        [Parameter(ParameterSetName = 'New')][string]$GroupName,
        [Parameter(ParameterSetName = 'New')][string]$DataType,
        [Parameter(ParameterSetName = 'New')][string]$Description,
        [Parameter(ParameterSetName = 'New')][string]$Prefix,
        [Parameter(Mandatory)][guid]$VocabId,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    if ($PsCmdlet.ParameterSetName -eq 'Existing') {
        $DisplayName = $Object.displayName
        $GroupName = $Object.groupName
        $DataType = $Object.dataType
        $Description = $Object.description
        $Prefix = $Object.name
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createVocabularyKey'

    $query = @{
        variables =@{
            vocabularyKey = @{
                vocabularyId = $VocabId
                displayName = $DisplayName
                name = $Prefix
                groupName = $GroupName
                isVisible = $true
                dataType = $DataType
                description = $Description
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
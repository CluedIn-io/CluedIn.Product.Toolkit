function New-CluedInVocabularyKey {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Vocabulary Key under a Vocabulary

        .DESCRIPTION
        GraphQL Query: Creates a New Vocabulary Key under a Vocabulary

        .PARAMETER Object
        Due to the complexity of the function, it is recommended to be passed in as a PSCustomObject.

        You can get a sample object by running Get-CluedInVocabularyKey and filtering down to the key result

        .EXAMPLE
        PS> New-CluedInVocabularyKey -Object $vocabularyKeyObject
    #>

    param(
        [Parameter(ParameterSetName = 'New')][string]$DisplayName,
        [Parameter(ParameterSetName = 'New')][string]$GroupName,
        [Parameter(ParameterSetName = 'New')][string]$DataType,
        [Parameter(ParameterSetName = 'New')][string]$Storage,
        [Parameter(ParameterSetName = 'New')][string]$Description,
        [Parameter(ParameterSetName = 'New')][string]$Prefix,
        [Parameter(Mandatory)][guid]$VocabId,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    if ($PsCmdlet.ParameterSetName -eq 'Existing') {
        $DisplayName = $Object.displayName
        $GroupName = $Object.groupName
        $DataType = $Object.dataType
        $Storage = $Object.storage
        $Description = $Object.description
        $Prefix = $Object.name
        $isVisible = $Object.isVisible
        $glossaryTermId = $Object.glossaryTermId
    }
    else { $isVisible = $true }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createVocabularyKey'

    $query = @{
        variables =@{
            vocabularyKey = @{
                vocabularyId = $VocabId
                displayName = $DisplayName
                name = $Prefix
                groupName = $GroupName
                isVisible = $isVisible
                dataType = $DataType
                storage = $Storage
                description = $Description
                glossaryTermId = $GlossaryTermId
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
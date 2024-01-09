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
        $isVisible = $Object.isVisible
        $isObsolete = $object.isObsolete
    }
    else { $isVisible = $true; $isObsolete = $false }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createVocabularyKey'

    $query = @{
        variables =@{
            vocabularyKey = @{
                vocabularyId = $VocabId
                displayName = $DisplayName
                name = $Prefix
                groupName = $GroupName
                isVisible = $isVisible
                isObsolete = $isObsolete
                dataType = $DataType
                description = $Description
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
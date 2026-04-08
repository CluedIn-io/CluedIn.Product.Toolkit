function Set-CluedInManualDataEntryProjectFormField {
    <#
        .SYNOPSIS
                Sets a manual data entry project form field configuration


        .DESCRIPTION
        Sets a manual data entry project form field configuration

        .PARAMETER FormFieldId
        This is the guid Id of the form field being updated

        .PARAMETER ProjectId
        This is the guid Id of the project to which the form field belongs

        .PARAMETER VocabularyKeyId
        This is the guid Id of the vocabulary to which the manual data entry project belongs

        .PARAMETER Object
        This is a ManualDataEntryProject object obtained from Get-CluedInManualDataEntryProject. It must be passed in full.

        .EXAMPLE
        PS> Set-CluedInManualDataEntryProjectFormField -FormFieldId 'ac1abbc4-cd21-442c-a89d-af5a5bc6813e' -ProjectId 'b20bc5d5-df32-453d-b90e-b06b6cd7924f' -VocabularyId 'c30cd6e6-eg43-464e-c01f-c17c7de8035g' -Object $ManualDataEntryProjectObject
    #>
    
    param(
        [guid]$FormFieldId,
        [guid]$ManualDataEntryProjectId,
        [guid]$VocabularyKeyId,
        [PSCustomObject]$Object
    )
    
    $queryContent = Get-CluedInGQLQuery -OperationName 'saveManualDataEntryProjectFormField'
    $query = @{
        query     = $queryContent
        variables = @{
            projectId = $ManualDataEntryProjectId
            formField = @{
                label                      = $Object.label
                type                       = $Object.type
                isRequired                 = $Object.isRequired
                onlyExistingValues         = $Object.onlyExistingValues
                useAsEntityCode            = $Object.useAsEntityCode
                description                = $Object.description
                parameters                 = $Object.parameters
                id                         = $FormFieldId
                vocabularyKey              = $Object.vocabularyKeyObject.key
                currentVocabularyKey       = $Object.vocabularyKeyObject.key
                vocabularyKeyConfiguration = @{
                    new= $false
                    vocabularyKeyName= $Object.vocabularyKeyObject.key
                    vocabularyKeyId= $VocabularyKeyId
                }
            }

        }  
    }

    return Invoke-CluedInGraphQL -Query $query
}
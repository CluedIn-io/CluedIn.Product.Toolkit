function New-CluedInManualDataEntryProjectFormField {
    <#
        .SYNOPSIS
        GraphQL Query= Creates a Manual Data Entry Project Form Field

        .DESCRIPTION
        GraphQL Query= Creates a Manual Data Entry Project Form Field

        .PARAMETER Object
        The ManualaDataEntryProjectFormField Object

        .EXAMPLE
        PS> New-CluedInManualDataEntryProjectFormField -Name "Sample Term" -Object $manaualDataEntryProjectFormFieldObject
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][PSCustomObject]$ManualDataEntryProjectId,
        [Parameter(Mandatory = $true)][PSCustomObject]$VocabularyKeyId,
        [Parameter(Mandatory = $true)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'addManualDataEntryProjectFormField'

    $variables = @{
        projectId = $ManualDataEntryProjectId
        formField = @{
            vocabularyKeyConfiguration = @{
                new               = $false # Expect this to be included as part of the vocabulary migration
                vocabularyKeyName = $Object.vocabularyKeyObject.key
                vocabularyKeyId   = $VocabularyKeyId
            }
            label                      = $Object.label
            type                       = $Object.type
            isRequired                 = $Object.isRequired
            onlyExistingValues         = $Object.onlyExistingValues
            useAsEntityCode            = $Object.useAsEntityCode
            description                = $Object.description
            parameters                 = $Object.parameters
        }
    }

    $query = @{
        variables = $variables
        query     = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

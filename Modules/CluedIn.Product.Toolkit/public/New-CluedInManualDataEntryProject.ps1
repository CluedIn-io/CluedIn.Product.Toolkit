function New-CluedInManualDataEntryProject {
    <#
        .SYNOPSIS
        GraphQL Query= Creates a Manual Data Entry Project

        .DESCRIPTION
        GraphQL Query= Creates a Manual Data Entry Project

        .PARAMETER Object
        The ManualaDataEntryProject Object

        .EXAMPLE
        PS> New-CluedInManualDataEntryProject -Name "Sample Term" -Object $manaualDataEntryProjectObject
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][PSCustomObject]$VocabularyId,
        [Parameter(Mandatory = $true)][PSCustomObject]$Object,
        [bool]$newEntityTypeConfiguration = $false
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createManualDataEntryProject'

    $variables = @{
        manualDataEntryProject = @{
            title                   =  $Object.title
            entityType              = $Object.entityType
            requireApproval         = $Object.requireApproval
            description             = $Object.description
            entityTypeConfiguration = @{
                new         = $newEntityTypeConfiguration
                icon        = $Object.entityTypeConfiguration.icon
                entityType  = $Object.entityTypeConfiguration.entityType
                displayName = $Object.entityTypeConfiguration.displayName
            }
            vocabularyConfiguration = @{
                new            = $false # Expect this to be included as part of the vocabulary migration
                vocabularyName = $Object.vocabulary.vocabularyName
                keyPrefix      = $Object.vocabulary.keyPrefix
                vocabularyId   = $VocabularyId
            }
        }
    }

    $query = @{
        variables = $variables
        query     = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

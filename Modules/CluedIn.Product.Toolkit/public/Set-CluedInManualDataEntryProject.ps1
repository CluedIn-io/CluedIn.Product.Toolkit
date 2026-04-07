function Set-CluedInManualDataEntryProject {
    <#
        .SYNOPSIS
        GraphQL Query= Sets a streams configuration

        .DESCRIPTION
        GraphQL Query= Sets a streams configuration

        .PARAMETER Id
        This is the guid Id of the stream being updated

        .PARAMETER VocabularyId
        This is the guid Id of the vocabulary to which the manual data entry project belongs

        .PARAMETER Object
        This is a ManualDataEntryProject object obtained from Get-CluedInManualDataEntryProject. It must be passed in full.

        .EXAMPLE
        PS> Set-CluedInManualDataEntryProject -Id 'ac1abbc4-cd21-442c-a89d-af5a5bc6813e' -Object $ManualDataEntryProjectObject
    #>

    param(
        [guid]$Id,
        [guid]$VocabularyId,
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveManualDataEntryProject'
    $query = @{
        query     = $queryContent
        variables = @{
            id                     = $Id
            manualDataEntryProject = @{
                title                   = $Object.title
                entityType              = $Object.entityType
                requireApproval         = $Object.requireApproval
                description             = $Object.description
                vocabularyConfiguration = @{
                    vocabularyId   = $VocabularyId
                    vocabularyName = $Object.vocabulary.vocabularyName
                    keyPrefix      = $Object.vocabulary.keyPrefix
                    new            = $false #TODO: How to set?!
                }
            }
        }  
    }

    return Invoke-CluedInGraphQL -Query $query
}
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
        [Parameter(Mandatory = $true)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createManualDataEntryProject'

    $variables = @{
        manualDataEntryProject = @{
            title                   =  $Object.title
            entityType              = $Object.entityType
            requireApproval         = $Object.requireApproval
            description             = $Object.description
            entityTypeConfiguration = @{
                new         = $false #TODO: How to set?!
                icon        = $Object.entityTypeConfiguration.icon
                entityType  = $Object.entityTypeConfiguration.entityType
                displayName = $Object.entityTypeConfiguration.displayName
            }
            vocabularyConfiguration = @{
                new            = $false #TODO: How to set?!
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

function New-CluedInVocabulary {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Vocabulary

        .DESCRIPTION
        GraphQL Query: Creates a New Vocabulary

        .PARAMETER Object
        Due to the complexity of the function, it is recommended to be passed in as a PSCustomObject.

        You can run Get-CluedInVocabulary and filter down to the vocabulary for a sample

        .EXAMPLE
        PS> New-CluedInVocabulary -Object $vocabularyObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'New')][string]$DisplayName,
        [Parameter(ParameterSetName = 'New')][string]$EntityCode,
        [Parameter(ParameterSetName = 'New')][string]$Provider,
        [Parameter(ParameterSetName = 'New')][string]$Prefix,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    switch ($PsCmdlet.ParameterSetName) {
        'Existing' {
            $DisplayName = $Object.vocabularyName
            $EntityCode = $Object.grouping
            $Provider = ''
            $Prefix = $Object.keyPrefix
            $description = $Object.description
            $entityTypeConfiguration = @{
                new = $false
                icon = $object.entityTypeConfiguration.icon
                entityType = $object.entityTypeConfiguration.entityType
                displayName = $object.entityTypeConfiguration.displayName
            }
        }
        default {
            $entityTypeConfiguration = @{
                new = $false
                icon = ''
                entityType = $EntityCode
                displayName = ''
            }
            $description = @(
                @{
                    type = 'paragraph'
                    children = @(
                        @{
                            text = ''
                        }
                    )
                }
            ) | ConvertTo-Json -Depth 20 -AsArray -Compress
        }
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createVocabulary'

    $query = @{
        variables = @{
            vocabulary = @{
                vocabularyName = $DisplayName
                entityTypeConfiguration = $entityTypeConfiguration
                providerId = $Provider
                keyPrefix = $Prefix
                description = $Description
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
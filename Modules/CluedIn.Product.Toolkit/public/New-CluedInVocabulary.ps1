function New-CluedInVocabulary {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Vocabulary

        .DESCRIPTION
        GraphQL Query: Creates a New Vocabulary

        .EXAMPLE
        PS> New-CluedInVocabulary
    #>

    [CmdletBinding()]
    param(
        [string]$DisplayName,
        [int]$EntityCode,
        [string]$Provider,
        [string]$Prefix
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createVocabulary'
    
    $query = @{
        variables = @{
            vocabulary = @{
                vocabularyName = $DisplayName
                entityTypeConfiguration = @{
                    new = 'false'
                    icon = 'Idea'
                    entityType = $EntityCode
                    displayName = ""
                }
                providerId = $Provider
                keyPrefix = $Prefix
                description = @(
                    @{
                        type = 'paragraph'
                        children = @(
                            @{
                                text = 'desc'
                            }
                        )
                    }
                )
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
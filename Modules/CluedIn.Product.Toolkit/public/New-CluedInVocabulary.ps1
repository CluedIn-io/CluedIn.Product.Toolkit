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
        [Parameter(ParameterSetName = 'New')][string]$DisplayName,
        [Parameter(ParameterSetName = 'New')][string]$EntityCode,
        [Parameter(ParameterSetName = 'New')][string]$Provider,
        [Parameter(ParameterSetName = 'New')][string]$Prefix,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    if ($PsCmdlet.ParameterSetName -eq 'Existing') {
        $DisplayName = $Object.vocabularyName
        $EntityCode = $Object.grouping
        $Provider = ''
        $Prefix = $Object.keyPrefix
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createVocabulary'
    
    $query = @{
        variables = @{
            vocabulary = @{
                vocabularyName = $DisplayName
                entityTypeConfiguration = @{
                    new = $false
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
                                text = 'Some random description that might be useful'
                            }
                        )
                    }
                ) | ConvertTo-Json -Depth 20 -AsArray -Compress
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
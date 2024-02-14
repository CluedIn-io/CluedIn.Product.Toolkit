function Set-CluedInGlossaryTerm {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the Glossary Term configuration

        .DESCRIPTION
        GraphQL Query: Sets the Glossary Term configuration

        .PARAMETER

        .PARAMETER

        .EXAMPLE
        PS> Set-CluedInGlossaryTerm
    #>

    [CmdletBinding()]
    param(

    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveGlossaryTerm'

    # Do we endorse?

    $query = @{
        variables = @{
            term = @{
                id = ''
                name = ''
                active = ''
                ownedBy = ''
                shortDescription = ''
                certificationLevel = ''
                description = ''
                isObsolete = ''
                categoryId = ''
                ruleSet = @{
                    rules = @()
                }
                relatedTags = @()
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
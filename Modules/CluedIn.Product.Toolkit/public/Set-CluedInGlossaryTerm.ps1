function Set-CluedInGlossaryTerm {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the Glossary Term configuration

        .DESCRIPTION
        GraphQL Query: Sets the Glossary Term configuration

        .PARAMETER Object
        This is the object of an exported Glossary Term

        .PARAMETER Id
        This is the id of the new Glossary Term to be configured

        .PARAMETER GlossaryId
        This is the id of the Glossary the Glossary Term is assigned to

        .EXAMPLE
        PS> Set-CluedInGlossaryTerm
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id,
        [Parameter(Mandatory)][PSCustomObject]$Object,
        [Parameter(Mandatory)][guid]$GlossaryId
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveGlossaryTerm'

    $ruleSet = $Object.ruleSet
    if($ruleSet -eq $null)
    {
        $ruleSet = [PSCustomObject]@{
            Rules = @()
        }
    }

    # Initialize an empty array for the new tags list
    $newRelatedTagsList = @()
    if ($Object.relatedTags) {
        # Get Current tags
        $glossaryTerms = Get-CluedInGlossaryTags

        # Loop through each related tag
        foreach ($tag in $Object.relatedTags) {
            $existingTag = $glossaryTags | Where-Object { $_.name -eq $tag.name }

            if ($existingTag) {
                # If the name exists, add existing name and id
                $newRelatedTagsList += [PSCustomObject]@{
                    id   = $existingTag.id
                    name = $existingTag.name
                }
            } else {
                # If the name does not exist, add just the name
                $newRelatedTagsList += [PSCustomObject]@{
                    name = $tag.name
                }
            }
        }
    }

    $query = @{
        variables = @{
            term = @{
                id = $Id
                name = $Object.name
                active = $Object.active
                shortDescription = $Object.shortDescription
                certificationLevel = $Object.certificationLevel
                description = $Object.description
                isObsolete = $Object.isObsolete
                categoryId = $GlossaryId
                ruleSet = $ruleSet
                relatedTags = $newRelatedTagsList
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

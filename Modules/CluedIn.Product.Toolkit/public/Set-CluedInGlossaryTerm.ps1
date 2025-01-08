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

    $relatedTags = @()
    if ($Object.relatedTags) {
        $relatedTags = $Object.relatedTags | Select-Object -ExpandProperty name
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
                relatedTags = $relatedTags
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

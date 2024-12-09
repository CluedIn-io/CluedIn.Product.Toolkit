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

        .EXAMPLE
        PS> Set-CluedInGlossaryTerm
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveGlossaryTerm'

    $ruleSet = $Object.ruleSet
    if($ruleSet -eq $null)
    {
        $ruleSet = [PSCustomObject]@{
            Rules = @()
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
                ruleSet = $ruleSet
                relatedTags = $Object.relatedTags
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
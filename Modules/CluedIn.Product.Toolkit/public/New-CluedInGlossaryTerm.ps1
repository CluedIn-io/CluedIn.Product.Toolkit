function New-CluedInGlossaryTerm {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a Glossary Term against a specified Glossary

        .DESCRIPTION
        GraphQL Query: Creates a Glossary Term against a specified Glossary

        .PARAMETER Name
        The name of the glossary term

        .PARAMETER GlossaryId
        You can run Get-CluedInGlossary to get the given Id. Which can then be used here.

        .EXAMPLE
        PS> New-CluedInGlossaryTerm -Name "Sample Term" -GlossaryId 'f86ffc29-1963-4a70-b9a8-73de5f007a42'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Name,
        [guid]$GlossaryId
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createGlossaryTerm'

    $query = @{
        variable = @{
            term = @{
                name = $Name
                categoryId = $GlossaryId
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
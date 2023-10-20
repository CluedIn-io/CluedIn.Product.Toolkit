function New-CluedInGlossaryTerm {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a Glossary Term

        .DESCRIPTION
        GraphQL Query: Creates a Glossary Term

        .EXAMPLE
        PS> New-CluedInGlossaryTerm
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Name,
        [string]$Glossary
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createGlossaryTerm'

    $query = @{
        variable = @{
            term = @{
                name = $Name
                categoryId = 'guid'
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
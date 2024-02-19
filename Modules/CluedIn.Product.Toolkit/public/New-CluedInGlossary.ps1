function New-CluedInGlossary {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new Glossary based on specified Name

        .DESCRIPTION
        GraphQL Query: Creates a new Glossary based on specified Name

        .EXAMPLE
        PS> New-CluedInGlossary -Name "Sample Glossary"

        This will create a new glossary categry called "Sample Glossary"
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Name
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createGlossaryCategory'

    $query = @{
        variables = @{
            category = @{
                name = $Name
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
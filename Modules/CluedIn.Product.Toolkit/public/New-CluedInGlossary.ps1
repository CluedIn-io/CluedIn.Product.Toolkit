function New-CluedInGlossary {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all Glossaries

        .DESCRIPTION
        GraphQL Query: Returns all Glossaries

        .EXAMPLE
        PS> Get-CluedInGlossary
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Name
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createGlossaryCategory'

    $query = @{
        variable = @{
            category = @{
                name = $Name
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
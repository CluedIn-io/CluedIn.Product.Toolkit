function Set-CluedInAnnotation {
    <#
        .SYNOPSIS
        GraphQL Query: Sets specific settings for Annotations

        .DESCRIPTION
        GraphQL Query: Sets specific settings for Annotations

        .EXAMPLE
        PS> Set-CluedInAnnotation
    #>

    [CmdletBinding()]
    param(
        [int]$Id,
        [hashtable]$Settings
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'modifyAnnotation'

    $query = @{
        variables = @{
            annotation = @{
                id = $Id
                #useDefaultSourceCode = $true
                #useStrictEdgeCode = $true
                #descriptionKey = ''
                #nameKey = ''
                #originEntityCodeKey = ''
                #origin = ''
            } + $Settings
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
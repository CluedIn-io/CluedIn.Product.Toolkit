function Set-CluedInAnnotation {
    <#
        .SYNOPSIS
        GraphQL Query: Sets specific settings for Annotations

        .DESCRIPTION
        GraphQL Query: Sets specific settings for Annotations

        .PARAMETER Id
        This is the annotationId we want to set these settings against

        .PARAMETER Settings
        This needs to be passed in as a hashtable. Some examples are:
        [bool]useDefaultSourceCode, [bool]useStrictEdgeCode, [string]descriptionKey, [string]nameKey,
        [string]originEntityCodeKey, [string]origin

        .EXAMPLE
        PS> $settings = @{useDefaultSourceCode = $true; nameKey = 'SomeKey'}
        PS> Set-CluedInAnnotation -Id 1 -Settings $settings

        This will set 'useDefaultSourceCode' to True and update 'nameKey' to use 'SomeKey'.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Id,
        [Parameter(Mandatory)][hashtable]$Settings
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
function Set-CluedInPreProcessDataSetRule {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new Pre Processing Data Set Rule

        .DESCRIPTION
        GraphQL Query: Creates a new Pre Processing Data Set Rule

        .PARAMETER Id
        The id of the pre process rule that will be updated

        .PARAMETER Configuration
        The json object that was exported

        .EXAMPLE
        PS> Set-CluedInPreProcessDataSetRule -Id 1 -Configuration $configuration 
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][PSCustomObject]$Configuration
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'savePreProcessDataSetRule'

    $query = @{
        variables = @{
            rule = @{
                id = $Id
                displayName = $Configuration.displayName
                isActive = $Configuration.isActive
                transformations = $Configuration.transformations
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Get-CluedPreProcessDataSetRules {
    <#
        .SYNOPSIS
        GraphQL Query: Returns information about Pre-process data set rules

        .DESCRIPTION
        GraphQL Query: Returns information about Pre-process data set rules

        .PARAMETER Id
        The annotation Id that you want to retrieve the Pre-process data set rules for

        .EXAMPLE
        PS> Get-CluedPreProcessDataSetRules
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Id
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'getAllPreProcessDataSetRules'

    $query = @{
        variables = @{
            annotationId = $Id
            page = 0
            pageSize = 20
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
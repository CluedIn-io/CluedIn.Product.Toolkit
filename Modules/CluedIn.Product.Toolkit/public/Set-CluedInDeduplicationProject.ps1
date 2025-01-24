function Set-CluedInDeduplicationProject {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the configuration of a Clean Project

        .DESCRIPTION
        GraphQL Query: Sets the configuration of a Clean Project

        .PARAMETER Id
        This is the Id of the project to update

        .PARAMETER Object
        This can be passed in as an PSCustomObject

        .EXAMPLE
        PS> Set-CluedInDeduplicationProject.ps1 -Id 604d4429-eae5-4a41-a321-83cfd2cdd01a -Object $CleanObject

        This will ensure the Id is set to the desired configuration state
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveDeduplicationProject'

    $query = @{
        variables = @{
            id = $Id
            dedupProject = @{
                name = $Object.name
                description = $Object.description
                deduplicationScopeFilter = $Object.deduplicationScopeFilter
                deduplicationScopeFilterType = $Object.deduplicationScopeFilterType
                shouldLimitQuerySize = $Object.shouldLimitQuerySize
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
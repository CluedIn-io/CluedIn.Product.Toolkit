function Set-CluedInCleanProject {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the configuration of a Clean Project

        .DESCRIPTION
        GraphQL Query: Sets the configuration of a Clean Project

        .EXAMPLE
        PS> Set-CluedInCleanProject -Id 604d4429-eae5-4a41-a321-83cfd2cdd01a -Object $CleanObject

        This will ensure the Id is set to the desired configuration state
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'updateNewCleanProject'

    if ($Object.fields.displayName -or $Object.fields.icon) {
        [array]$Object.fields = $Object.fields | Foreach-Object {
            $_ | select-Object * -ExcludeProperty displayName, icon
        }
    }

    $query = @{
        variables = @{
            id = $Id
            cleanProject = @{
                name = $Object.name
                query = $Object.query
                includeDataParts = $Object.includeDataParts
                fields = $Object.fields
                description = $Object.description
                condition = $Object.condition
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
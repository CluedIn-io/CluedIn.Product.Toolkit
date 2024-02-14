function New-CluedInCleanProject {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all clean projects

        .DESCRIPTION
        GraphQL Query: Returns all clean projects

        .EXAMPLE
        PS> Get-CluedInCleanProjects

        This will return back all Clean Projects
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createNewCleanProject'

    $query = @{
        variables = @{
            cleanProject = @{
                name = $Name
                query = ''
                includeDataParts = ''
                fields = @()
                description = ''
                condition = @{}
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
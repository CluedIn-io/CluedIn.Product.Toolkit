function New-CluedInDeduplicationProject {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all clean projects

        .DESCRIPTION
        GraphQL Query: Returns all clean projects

        .PARAMETER Name
        This is the name of the Deduplication Project as it appears in the GUI

        .PARAMETER Object
        This can be passed in as an PSCustomObject

        .EXAMPLE
        PS> New-CluedInDeduplicationProject -Name 'NameOfProject' -Object $object

        This will add a deduplication project
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDeduplicationProject'

    $query = @{
        variables = @{
            dedupProject = @{
                name = $Name
                deduplicationScopeFilterType = $Object.deduplicationScopeFilterType
                deduplicationScopeFilter = $Object.deduplicationScopeFilter
                shouldLimitQuerySize = $Object.shouldLimitQuerySize
                querySizeLimit = $Object.querySizeLimit
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function New-CluedInDataSourceSet {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New DataSource Set

        .DESCRIPTION
        GraphQL Query: Creates a New DataSource Set

        .EXAMPLE
        PS> New-CluedInDataSourceSet
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'New')][int]$AuthorID,
        [Parameter(ParameterSetName = 'New')][string]$DisplayName,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    $me = Get-CluedInMe

    if ($PsCmdlet.ParameterSetName -eq 'Existing') {
        $AuthorID = $me.data.administration.me.client.id
        $DisplayName = $Object.name
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDataSourceSet'

    $query = @{
        variables =@{
            dataSourceSet = @{
                name = $DisplayName
                author = $AuthorID
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
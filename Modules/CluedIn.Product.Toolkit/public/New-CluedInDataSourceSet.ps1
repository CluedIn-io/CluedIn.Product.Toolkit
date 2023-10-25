function New-CluedInDataSourceSet {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New DataSource Set

        .DESCRIPTION
        GraphQL Query: Creates a New DataSource Set

        .PARAMETER DisplayName
        This is the name of the Data Source Set as it appears in the GUI

        .PARAMETER Object
        This can be passed in as an PSCustomObject

        .EXAMPLE
        PS> New-CluedInDataSourceSet -DisplayName 'Sample Data Source Set'
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'New')][guid]$AuthorID,
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
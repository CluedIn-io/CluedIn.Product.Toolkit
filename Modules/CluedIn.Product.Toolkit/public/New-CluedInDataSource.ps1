function New-CluedInDataSource {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New DataSource 

        .DESCRIPTION
        GraphQL Query: Creates a New DataSource 

        .EXAMPLE
        PS> New-CluedInDataSource
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'New')][int]$DataSourceSetID,
        [Parameter(ParameterSetName = 'New')][guid]$AuthorID,
        [Parameter(ParameterSetName = 'New')][string]$Name,
        [string]$SourceType,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    $me = Get-CluedInMe

    if ($PsCmdlet.ParameterSetName -eq 'Existing') {
        $AuthorID = $me.data.administration.me.client.id
        $DataSourceSetID = $Object.dataSourceSet.id
        $Name = $Object.name
        $SourceType = $Object.type
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDataSource'

    $query = @{
        variables = @{
            dataSourceSetId = $DataSourceSetID
            dataSource = @{
                author = $AuthorID
                type = $SourceType
                name = $Name
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
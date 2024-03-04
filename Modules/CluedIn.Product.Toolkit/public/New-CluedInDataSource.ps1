function New-CluedInDataSource {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New DataSource

        .DESCRIPTION
        GraphQL Query: Creates a New DataSource

        .PARAMETER Object
        Due to the complexity of the function, it is recommended to be passed in as a PSCustomObject.

        You can get a sample object by running Get-CluedInDataSource

        .EXAMPLE
        PS> New-CluedInDataSource -Object $DataSourceObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'New')][int]$DataSourceSetID,
        [Parameter(ParameterSetName = 'New')][string]$Name,
        [string]$SourceType = 'endpoint',
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    $me = Get-CluedInMe

    if ($PsCmdlet.ParameterSetName -eq 'Existing') {
        $DataSourceSetID = $Object.dataSourceSet.id
        $Name = $Object.name
        $SourceType = $Object.type
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDataSource'

    $query = @{
        variables = @{
            dataSourceSetId = $DataSourceSetID
            dataSource = @{
                author = $me.data.administration.me.client.id
                type = $SourceType
                name = $Name
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
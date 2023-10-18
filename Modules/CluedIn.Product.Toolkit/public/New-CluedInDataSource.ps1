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
        [int]$DataSourceSetID,
        [int]$AuthorID,
        [string]$Name
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDataSource'

    $query = @{
        variables = @{
            dataSourceSetId = $DataSourceSetID
            dataSource = @{
                author = $AuthorID
                type = 'endpoint'
                name = $Name
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
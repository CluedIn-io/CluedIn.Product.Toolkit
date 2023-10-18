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
        [int]$AuthorID,
        [string]$DataSourceSetName 
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDataSourceSet'

    $query = @{
        variables =@{
            dataSourceSet = @{
                name = $DataSourceSetName
                author = $AuthorID
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
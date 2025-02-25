function Set-CluedInDataSourceDatabaseConfiguration {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the quality configuration against a Data Source

        .DESCRIPTION
        GraphQL Query: Sets the quality configuration against a Data Source

        .EXAMPLE
        PS> Set-CluedInDataSourceConfiguration -Object $CustomObject
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$DataSourceId,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveDataBaseConfigurationForDataSource'

    $queryVariables = @{
        id = $DataSourceId
        configuration= @{
            id= $DataSourceId
            dialect = $Object.sql.dialect
            host = $Object.sql.host
            username = $Object.sql.username
            password = $null
            database = $Object.sql.database
            port = $Object.sql.port
            encrypt = $Object.sql.encrypt
        }
    }

    $query = @{
        variables = $queryVariables
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
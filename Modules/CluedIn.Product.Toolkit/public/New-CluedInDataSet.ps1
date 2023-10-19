function New-CluedInDataSet {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Dataset 

        .DESCRIPTION
        GraphQL Query: Creates a New Dataset 

        .EXAMPLE
        PS> New-CluedInDataSet -Id 10
        
        This will query will return mapping id '10' for the connected CluedIn Organisation
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'New')][int]$DataSourceID,
        [Parameter(ParameterSetName = 'New')][int]$AuthorID,
        [Parameter(ParameterSetName = 'New')][string]$Name,
        [Parameter(ParameterSetName = 'New')][string]$EntityType,
        [Parameter(ParameterSetName = 'New')][string]$EnityTypeDisplayName,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDataSets'

    $query = @{
        variables = @{
            dataSourceId = $DataSourceID
            dataSets = @(
                @{
                    author = $AuthorID
                    store = 'true'
                    type = 'endpoint'
                    name = $Name
                    configuration = @{
                        object = @{
                            endPointName = $Name
                            autoSubmit = 'false'
                            entityType = '/Employee'
                        }
                        entityTypeConfiguration = @{
                            new = 'false'
                            icon = 'Person'
                            entityType = $EntityType
                            displayName = $EnityTypeDisplayName
                        }
                    }
                }
            )
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
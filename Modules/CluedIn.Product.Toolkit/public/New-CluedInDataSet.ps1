function New-CluedInDataSet {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Dataset

        .DESCRIPTION
        GraphQL Query: Creates a New Dataset

        .PARAMETER Object
        The preferred way of creating a Data Set due to the complex nature of the function.

        You can use Get-CluedInDataSet to see an example PSCustomObject when filtered down to the data

        .EXAMPLE
        PS> $dataSet = Get-CluedInDataSet -id 67ab03ee-44b2-40b2-a911-90f094e2f294
        PS> $dataSetObject = $dataSet.data.inbound.dataSet
        PS> New-CluedInDataSet -Object $dataSetObject

        This will query will return mapping id '10' for the connected CluedIn Organization
    #>

    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = 'New')][int]$DataSourceID,
        [Parameter(ParameterSetName = 'New')][guid]$AuthorID,
        [Parameter(ParameterSetName = 'New')][string]$Name,
        [Parameter(ParameterSetName = 'New')][string]$EntityType,
        [Parameter(ParameterSetName = 'New')][string]$EnityTypeDisplayName,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    $me = Get-CluedInMe

    if ($PsCmdlet.ParameterSetName -eq 'Existing') {
        $DataSourceID = $Object.dataSource.id
        $AuthorID = $me.data.administration.me.client.id
        $Name = $Object.name
        $Configuration = $Object.configuration
        $type = $Object.dataSource.type
    }
    else {
        $Configuration = @{
            object = @{
                endPointName = $Name
                autoSubmit = $false
                entityType = '/Employee'
            }
            entityTypeConfiguration = @{
                new = $false
                icon = 'Person'
                entityType = $EntityType
                displayName = $EnityTypeDisplayName
            }
        }
        $type = 'endpoint'
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDataSets'

    $query = @{
        variables = @{
            dataSourceId = $DataSourceID
            dataSets = @(
                @{
                    author = $AuthorID
                    store = $true
                    type = $type
                    name = $Name
                    configuration = $Configuration
                }
            )
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
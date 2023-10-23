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
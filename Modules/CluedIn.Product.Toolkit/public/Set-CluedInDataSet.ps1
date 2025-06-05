function Set-CluedInDataSet {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a streams configuration

        .DESCRIPTION
        GraphQL Query: Sets a streams configuration

        .PARAMETER Id
        This is the guid Id of the stream being updated

        .PARAMETER Object
        This is a Stream object obtained from Get-CluedInDataSet. It must be passed in full.

        .EXAMPLE
        PS> Set-CluedInDataSet -Id 'ac1abbc4-cd21-442c-a89d-af5a5bc6813e' -Object $StreamObject
    #>

    param(
        [guid]$Id,
        [bool]$onlyUpdateClueHeadVersion
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveDataSet'

    $query = @{
        variables =@{
            dataSet = @{
                id = $Id
                onlyUpdateClueHeadVersion = $onlyUpdateClueHeadVersion
            }
        }

        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
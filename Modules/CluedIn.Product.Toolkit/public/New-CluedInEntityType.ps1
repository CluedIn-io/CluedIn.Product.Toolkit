function New-CluedInEntityType {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Entity Type

        .DESCRIPTION
        GraphQL Query: Creates a New Entity Type

        .EXAMPLE
        PS> New-CluedInEntityType
    #>

    [CmdletBinding()]
    param(
        [string]$DisplayName,
        [int]$TypeCode,
        [string]$TypeIcon,
        [int]$TypeRoute
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createEntityTypeConfiguration'

    $query = @{
        variables = @{
            entityTypeConfiguration = @{
                displayName = $DisplayName
                entityType = "/$TypeCode"
                icon = $TypeIcon
                route = $TypeRoute
                pageTemplateId = ""
            }
        }
        query = $queryContent
    }    

    return Invoke-CluedInGraphQL -Query $query
}
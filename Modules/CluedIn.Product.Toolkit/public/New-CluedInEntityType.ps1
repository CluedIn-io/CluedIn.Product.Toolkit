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
                type = $TypeCode
                active = $true
                displayName = $DisplayName
                icon = $TypeIcon
                route = $displayName.ToLower().Replace(' ','')
                pageTemplateId = ""
            } | ConvertTo-Json -Compress
        }
        query = $queryContent
    }

    "entityTypeConfiguration": "{\"type\":\"/fake\",\"active\":true,\"displayName\":\"fake\",\"icon\":\"Googleplus\",\"route\":\"fake\",\"pageTemplateId\":\"\"}"

    return Invoke-CluedInGraphQL -Query $query
}
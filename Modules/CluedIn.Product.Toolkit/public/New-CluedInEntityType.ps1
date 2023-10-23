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
        [Parameter(ParameterSetName = 'New')][string]$DisplayName,
        [Parameter(ParameterSetName = 'New')][string]$TypeCode,
        [Parameter(ParameterSetName = 'New')][string]$TypeIcon,
        [Parameter(ParameterSetName = 'Existing')][PSCustomObject]$Object
    )

    if ($PsCmdlet.ParameterSetName -eq 'Existing') {
        $DisplayName = $Object.displayName
        $TypeCode = $Object.entityType
        $TypeIcon = $Object.icon
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createEntityTypeConfiguration'

    $query = @{
        variables = @{
            entityTypeConfiguration = @{
                type = $TypeCode
                active = $true
                displayName = $DisplayName
                icon = $TypeIcon
                route = $DisplayName.ToLower().Replace(' ','')
                pageTemplateId = ""
            } | ConvertTo-Json -Compress
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
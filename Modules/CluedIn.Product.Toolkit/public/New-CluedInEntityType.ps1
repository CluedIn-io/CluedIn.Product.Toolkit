function New-CluedInEntityType {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a New Entity Type

        .DESCRIPTION
        GraphQL Query: Creates a New Entity Type

        .PARAMETER Object
        Due to the complexity of the function, it is recommended to be passed in as a PSCustomObject.

        You can see a sample object by running Get-CluedInEntityType and filtering down to the entity itself

        .EXAMPLE
        PS> New-CluedInEntityType -Object $entityObject
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
function Set-CluedInStream {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a streams configuration

        .DESCRIPTION
        GraphQL Query: Sets a streams configuration

        .PARAMETER Id
        This is the guid Id of the stream being updated

        .PARAMETER Object
        This is a Stream object obtained from Get-CluedInStream. It must be passed in full.

        .EXAMPLE
        PS> Set-CluedInStream -Id 'ac1abbc4-cd21-442c-a89d-af5a5bc6813e' -Object $StreamObject
    #>

    param(
        [guid]$Id,
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveStream'

    $query = @{
        variables =@{
            stream = @{
                id = $Id
                name = $Object.name
                description = $Object.description
                isActive = $Object.isActive
                condition = $Object.condition
                rules = $Object.rules
            }
        }

        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
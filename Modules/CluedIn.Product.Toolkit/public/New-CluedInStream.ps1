function New-CluedInStream {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a stream

        .DESCRIPTION
        GraphQL Query: Creates a stream

        .PARAMETER Name
        This is the display name of the Stream that appears under the Streams tab.

        .EXAMPLE
        PS> New-CluedInStream -Name 'My Stream'
    #>

    param(
        [string]$Name
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createStream'

    $query = @{
        variables =@{
            stream = @{
                name = $Name
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
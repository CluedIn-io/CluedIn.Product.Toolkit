function New-CluedInDeduplicationMatchingRule {
    <#
        .SYNOPSIS
        GraphQL Query: Returns all clean projects

        .DESCRIPTION
        GraphQL Query: Returns all clean projects

        .PARAMETER DeduplicationProjectId
        This is the ID of the Deduplication Project you want to add the matching rule to

        .PARAMETER Object
        This can be passed in as an PSCustomObject

        .EXAMPLE
        PS> New-CluedInDeduplicationMatchingRule -Id 'cc192b24-c705-44fe-9447-6af542b9ecd9' -Object $object

        This will add a matching rule to the deduplcation project
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$DeduplicationProjectId,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    function removeUnwantedProperties($Object){
        # Removing unwanted properties in the JSON object as GQL returns a 400 if they are left in place
        $Object.PSObject.Properties.Remove("__typename")
        
        foreach ($item in $Object.matchingCriteria) {
            $item.PSObject.Properties.Remove("__typename")
            $item.PSObject.Properties.Remove("matchingTypeDisplayName")

            foreach ($normalizationConfiguration in $item.normalizationConfiguration) {
                $normalizationConfiguration.PSObject.Properties.Remove("displayName")
            }
        }
    }

    $queryContent = Get-CluedInGQLQuery -OperationName 'createDeduplicationMatchingRule'

    removeUnwantedProperties($Object)

    $query = @{
        variables = @{
            id = $DeduplicationProjectId
            rule = @{
                name = $Object.name
                matchingCriteria = $Object.matchingCriteria
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
function Set-CluedInDeduplicationMatchingRule {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the configuration of a Clean Project

        .DESCRIPTION
        GraphQL Query: Sets the configuration of a Clean Project

        .PARAMETER Id
        This is the Id of the project to update

        .PARAMETER MatchingRuleId
        This is the Id of the matching rule to update

        .PARAMETER Object
        This can be passed in as an PSCustomObject

        .EXAMPLE
        PS> Set-CluedInDeduplicationMatchingRule.ps1 -Id 604d4429-eae5-4a41-a321-83cfd2cdd01a -Object $CleanObject

        This will ensure the Id is set to the desired configuration state
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id,
        [Parameter(Mandatory)][guid]$MatchingRuleId,
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

    $queryContent = Get-CluedInGQLQuery -OperationName 'updateDeduplicationMatchingRule'

    removeUnwantedProperties($Object)

    $query = @{
        variables = @{
            id = $Id
            ruleId = $MatchingRuleId
            rule = @{
                name = $Object.name
                matchingCriteria = $Object.matchingCriteria
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
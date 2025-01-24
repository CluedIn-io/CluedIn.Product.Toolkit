function Set-CluedInCleanProject {
    <#
        .SYNOPSIS
        GraphQL Query: Sets the configuration of a Clean Project

        .DESCRIPTION
        GraphQL Query: Sets the configuration of a Clean Project

        .EXAMPLE
        PS> Set-CluedInCleanProject -Id 604d4429-eae5-4a41-a321-83cfd2cdd01a -Object $CleanObject

        This will ensure the Id is set to the desired configuration state
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$Id,
        [Parameter(Mandatory)][PSCustomObject]$Object
    )

    function removeUnwantedProperties($Object){
        # Removing unwanted properties in the JSON object as GQL returns a 400 if they are left in place
        if($Object.fields.count -gt 0){
            foreach ($item in $Object.fields) {
                $item.PSObject.Properties.Remove("__typename")
                $item.PSObject.Properties.Remove("icon")
                $item.PSObject.Properties.Remove("displayName")
            }
        }
    
        $Object.condition.PSObject.Properties.Remove("id")
        $Object.condition.PSObject.Properties.Remove("type")
        $Object.condition.PSObject.Properties.Remove("value")
        $Object.condition.PSObject.Properties.Remove("operator")
        $Object.condition.PSObject.Properties.Remove("objectTypeId")
        $Object.condition.PSObject.Properties.Remove("field")
        $Object.condition.PSObject.Properties.Remove("__typename")
    
        if($Object.condition.rules.count -gt 0){
            removeUnwantedPropertyRecursivelyFromRules($Object.condition.rules)
        }
    }
    
    function removeUnwantedPropertyRecursivelyFromRules($ruleArray, $propertyName){
        foreach ($item in $ruleArray) {
            $item.PSObject.Properties.Remove("__typename")
            if($item.rules.count -gt 0){
                removeUnwantedPropertyRecursivelyFromRules($item.rules)
            }
        }
    }

    removeUnwantedProperties($Object)

    $queryContent = Get-CluedInGQLQuery -OperationName 'updateNewCleanProject'

    $query = @{
        variables = @{
            id = $Id
            cleanProject = @{
                name = $Object.name
                query = $Object.query
                includeDataParts = $Object.includeDataParts
                fields = $Object.fields
                description = $Object.description
                condition = $Object.condition
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}
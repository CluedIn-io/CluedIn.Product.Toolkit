function Set-CluedInRule {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a Rule's configuration

        .DESCRIPTION
        GraphQL Query: Sets a Rule's configuration

        .PARAMETER Object
        Due to the complexity of the function, it needs to be passed in as a PSCustomObject

        You can get a sample by running Get-CluedInRules and filtering it down to the rule configuration

        .EXAMPLE
        PS> Set-CluedInRule -Object $sampleRuleObject
    #>

    [CmdletBinding()]
    param(
        [PSCustomObject]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveRule'

    $query = @{
        query = $queryContent
        variables = @{
            rule = @{
                id = $Object.id
                name = $Object.name
                isActive = $Object.isActive
                description = $Object.description
                scope = $Object.scope
                condition = @{
                    objectTypeId = $Object.condition.objectTypeId
                    condition = $Object.condition.condition
                    field = $Object.condition.field
                    id = $Object.condition.id # Not sure what this is - do we need to update it?
                    operator = $Object.condition.operator
                    rules = @(
                        $Object.condition.rules.ForEach({
                            @{
                                condition = $_.condition
                                field = $_.field
                                objectTypeId = $_.objectTypeId # Not sure what this is - do we need to update it?
                                operator = $_.operator # Not sure what this is - do we need to update it?
                                value = $_.value
                                type = $_.type
                            }
                        })
                    )
                    type = $Object.condition.type
                    value = $Object.condition.value
                }
                rules = @(
                    $object.rules.ForEach({
                        @{
                            name = $_.name
                            isActive = $_.isActive
                            conditions = @{
                                rules = @(
                                    $_.conditions.rules.ForEach({
                                        @{
                                            condition = $_.condition
                                            field = $_.field
                                            objectTypeId = $_.objectTypeId
                                            operator = $_.operator
                                            value = $_.value
                                            type = $_.type
                                        }
                                    })
                                )
                                condition = $_.conditions.condition
                            }
                            actions = @(
                                @{
                                    name = $_.actions.name
                                    supportsPreview = $_.actions.supportsPreview
                                    type = $_.actions.type
                                    properties = @(
                                        @{
                                            name = $_.actions.properties.name
                                            type = $_.actions.properties.type
                                            value = $_.actions.properties.value
                                            isRequired = $_.actions.properties.isRequired
                                        }
                                    )
                                }
                            )
                        }
                    })
                )
            }
        }
    }

    return Invoke-CluedInGraphQL -Query $query
}
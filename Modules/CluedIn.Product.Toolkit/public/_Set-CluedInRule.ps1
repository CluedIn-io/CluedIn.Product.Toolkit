function Set-CluedInRule {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a Rule's configuration

        .DESCRIPTION
        GraphQL Query: Sets a Rule's configuration

        .EXAMPLE
        PS> Set-CluedInRule -RuleName 'TestRule'

        This will query will return mapping id '10' for the connected CluedIn Organisation
    #>

    [CmdletBinding()]
    param(
        [string]$Object
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'saveRule'

    $query = @{
        query = $queryContent
        variables = @{
            rule = @{
                id = $Id
                name = $RuleName
                isActive = $false
                description = $null
                scope = 'DataPart'
                condition = @{
                    objectTypeId = '00000000-0000-0000-0000-000000000000'
                    condition = 'AND'
                    field = $null
                    id = '81f89387-11b3-4f83-9f7c-bf13cd6fb45d'
                    operator = '00000000-0000-0000-0000-000000000000'
                    rules = @(
                        @{
                            condition = 'AND'
                            field = 'Aliases'
                            objectTypeId = '3be85371-cbe0-4180-8820-73e6e37a6c32'
                            operator = '4988d076-3ec1-4414-9f56-5b9b30e25f72'
                            value = @(
                                "admin@devcluedin.com"
                            )
                            type = 'enumerable'
                        }
                    )
                    type = $null
                    value = $null
                }
                rules = @(
                    @{
                        name = $ActionName
                        isActive = $false
                        conditions = @{
                            rules = @(
                                @{
                                    condition = 'AND'
                                    field = "Properties[organization.address]"
                                    objectTypeId = '011ac3b4-0b46-4f9c-a82a-8c14f9dd642b'
                                    operator = '4988d076-3ec1-4414-9f56-5b9b30e25f72'
                                    value = @(
                                        "asdf"
                                    )
                                    type = 'string'
                                }
                            )
                            condition = 'OR'
                        }
                        actions = @(
                            @{
                                name = "Add Tag"
                                supportsPreview = $false
                                type = "CluedIn.Rules.Actions.AddTag, CluedIn.Rules"
                                properties = @(
                                    @{
                                        name = "Value"
                                        type = "System.String"
                                        value = "asdfsdaf"
                                        isRequired = $true
                                    }
                                )
                            }
                        )
                    }
                )
            }
        }
    }

    return Invoke-CluedInGraphQL -Query $query
}
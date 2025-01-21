function New-CluedInPreProcessDataSetRule {
    <#
        .SYNOPSIS
        GraphQL Query: Creates a new Pre Processing Data Set Rule

        .DESCRIPTION
        GraphQL Query: Creates a new Pre Processing Data Set Rule

        .PARAMETER AnnotationId
        The annotation id that the preprocess rule will be assigned to

        .PARAMETER Configuration
        The json object that was exported

        .EXAMPLE
        PS> New-CluedInPreProcessDataSetRule -AnnotationId 1 -Configuration $configuration 
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$AnnotationId,
        [Parameter(Mandatory)][PSCustomObject]$Configuration
    )

    $queryContent = Get-CluedInGQLQuery -OperationName 'createPreProcessDataSetRule'

    $query = @{
        variables = @{
            rule = @{
                annotationId = $AnnotationId
                displayName = $Configuration.displayName
                transformations = $Configuration.transformations
            }
        }
        query = $queryContent
    }

    return Invoke-CluedInGraphQL -Query $query
}

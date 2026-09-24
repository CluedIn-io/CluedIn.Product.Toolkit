function Get-MatchingFieldMapping {
    <#
        .SYNOPSIS
        Finds the existing destination field mapping that a source field mapping should update

        .DESCRIPTION
        A single original field can have multiple mappings (ie. 'name' and 'name.Original'), so matching
        on originalField alone is ambiguous. This resolves to a single destination mapping, or $null when
        a new mapping should be created instead.

        Order of preference:
        1. An unclaimed destination mapping with the same originalField and key
        2. If the destination has at least as many mappings for the field as the source, an unclaimed
           destination mapping whose key isn't wanted by any source mapping for that field
        3. $null (create a new mapping)

        .PARAMETER Mapping
        The source field mapping being imported

        .PARAMETER SourceFieldMappings
        All field mappings from the source data set

        .PARAMETER CurrentFieldMappings
        All field mappings currently on the destination data set

        .PARAMETER ClaimedIds
        Destination mapping ids already matched to a source mapping during this import
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$Mapping,
        [PSCustomObject[]]$SourceFieldMappings,
        [PSCustomObject[]]$CurrentFieldMappings,
        [System.Collections.Generic.HashSet[string]]$ClaimedIds
    )

    $candidates = @($CurrentFieldMappings | Where-Object {
        $_.originalField -eq $Mapping.originalField -and !$ClaimedIds.Contains([string]$_.id)
    })
    if ($candidates.Count -eq 0) { return $null }

    $exactMatch = $candidates | Where-Object { $_.key -eq $Mapping.key } | Select-Object -First 1
    if ($exactMatch) { return $exactMatch }

    $sourceMappingsForField = @($SourceFieldMappings | Where-Object { $_.originalField -eq $Mapping.originalField })
    $destinationCount = @($CurrentFieldMappings | Where-Object { $_.originalField -eq $Mapping.originalField }).Count
    if ($destinationCount -lt $sourceMappingsForField.Count) { return $null }

    $sourceKeys = $sourceMappingsForField.key
    return $candidates | Where-Object { $_.key -notin $sourceKeys } | Select-Object -First 1
}

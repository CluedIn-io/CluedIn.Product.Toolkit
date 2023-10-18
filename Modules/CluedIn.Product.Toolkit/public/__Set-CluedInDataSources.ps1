function Set-CluedInDataSources {
    <#
        .SYNOPSIS
        GraphQL Query: Sets a data source

        .DESCRIPTION
        GraphQL Query: Sets a data source

        .EXAMPLE
        PS> Set-CluedInDataSources
    #>

    [CmdletBinding()]
    param ()

    $Query = Get-CI-Data -baseURL "$_baseURL" -token $Token -GQlQuery $QueryCluedInDatasets | ConvertFrom-Json

    foreach ($DSS in $Query.data.inbound.dataSourceSets.data) {
        Write-Host $DSS.name " id " $DSS.id
        $DSSID = $DSS.id
        $Path = "BackupFiles\DataSources\$DSSID" 
        
        New-Item -Path "$Path" -ItemType Directory
        $DSSName = $DSS.name
        $DSS | ConvertTo-Json -Depth 10  | Out-File -FilePath  "$Path\DSS-$DSSName.json"
        foreach ($DS in $DSS.dataSources) {
            Write-Host $DS.name " id " $DS.id

            $DSSName = $DS.name 
            New-Item -Path "$Path\$DSSName" -ItemType Directory
            $DS | ConvertTo-Json -Depth 10  | Out-File -FilePath  "$Path\$DSSName\DSRC-$DSSName.json"

            foreach ($DSE in $DS.dataSets) {
                $DSINfoQ = getDataSetById -DataSetId $DSE.id

                $DSInfo = Get-CI-Data -baseURL "$_baseURL" -token $Token -GQlQuery $DSINfoQ   | ConvertFrom-Json 

                Write-Host $DSInfo.data.inbound.dataSet.configuration.object.endPointName " - "$DSInfo.data.inbound.dataSet.id
                $MapingQ = getDataSetById -DataSetId $DSInfo.data.inbound.dataSet.id
                $MapingD = Get-CI-Data -baseURL "$_baseURL" -token $Token -GQlQuery $MapingQ| ConvertFrom-Json
                $DSetName = $DSInfo.data.inbound.dataSet.configuration.object.endPointName
                $MapingD | ConvertTo-Json -Depth 10  | Out-File -FilePath  "$Path\$DSSName\DSET-$DSetName.json"
            }
        }
    }
}
[CmdletBinding()]
param(
    [parameter(Mandatory)][string]$BaseURL,
    [parameter(Mandatory)][string]$Organization
)

Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organization

if ([version]${env:CLUEDIN_CURRENTVERSION} -lt [version]'4.0.0') { throw "Unable to support sample set data" }

Write-Host "Creating data source set"
$currentDirectory = $PSScriptRoot
$jsonPath = Join-Path -Path $currentDirectory -ChildPath 'sample-person.json'

$dataSourceSetPath = Join-Path -Path $currentDirectory -ChildPath 'jsons/Data/SourceSets/DataSourceSet.json'
$dataSourceSetObject = Get-Content -Path $dataSourceSetPath | ConvertFrom-Json -Depth 99
$dataSourceSet = New-CluedInDataSourceSet -Object $dataSourceSetObject.data.inbound.dataSourceSets.data

Write-Host "Creating data source"
$dataSourcePath = Join-Path -Path $currentDirectory -ChildPath 'jsons/Data/Sources/1-DataSource.json'
$dataSourceObject = Get-Content -Path $dataSourcePath | ConvertFrom-Json -Depth 99
$dataSourceObject.data.inbound.dataSource.dataSourceSet.id = $dataSourceSet.data.inbound.createDataSourceSet
$dataSource = New-CluedInDataSource -Object $dataSourceObject.data.inbound.dataSource

Write-Host "Creating data set"
$dataSetPath = Join-Path -Path $currentDirectory -ChildPath 'jsons/Data/Sets/'
$dataSets = Get-ChildItem -Path $dataSetPath
foreach ($set in $dataSets) {
    $dataSetObject = Get-Content -Path $set.FullName | ConvertFrom-Json -Depth 99
    $dataSetObject.data.inbound.dataSet.dataSourceId = $dataSource.data.inbound.createDataSource.id
    $dataSetObject.data.inbound.dataSet.dataSource.id = $dataSource.data.inbound.createDataSource.id

    $dataSet = New-CluedInDataSet -Object $dataSetObject.data.inbound.dataSet

    $endpointId = $dataSet.data.inbound.createDataSets.id

    Write-host "Sending data to data set id '$($endpointId)'"
    $jsonBlob = Get-Content -Path $jsonPath -Raw
    $sendResult = Send-CluedInIngestionData -Json $jsonBlob -IngestionEndpoint $endpointId
    if ($sendResult.error -eq 'True' ) { throw "Uh oh, we have a throw" }
}
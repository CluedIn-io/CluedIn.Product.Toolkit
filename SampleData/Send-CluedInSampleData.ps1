[CmdletBinding()]
param(
    [string]$BaseURL = '51.140.229.75.sslip.io',
    [string]$Organization = 'cluedin'
)

Connect-CluedInOrganisation -BaseURL $BaseURL -Organisation $Organization

if ([version]${env:CLUEDIN_CURRENTVERSION} -lt [version]'4.0.0') { throw "Unable to support sample set data" }

Write-Host "Creating data source set"
$dataSourceSetObject = Get-Content -Path './SampleData/jsons/Data/SourceSets/DataSourceSet.json' | ConvertFrom-Json -Depth 99
$dataSourceSet = New-CluedInDataSourceSet -Object $dataSourceSetObject.data.inbound.dataSourceSets.data

Write-Host "Creating data source"
$dataSourceObject = Get-Content -Path './SampleData/jsons/Data/Sources/1-DataSource.json' | ConvertFrom-Json -Depth 99
$dataSourceObject.data.inbound.dataSource.dataSourceSet.id = $dataSourceSet.data.inbound.createDataSourceSet
$dataSource = New-CluedInDataSource -Object $dataSourceObject.data.inbound.dataSource

Write-Host "Creating data set"
$dataSetObject = Get-Content -Path './SampleData/jsons/Data/Sets/55036A5C-7406-4F21-AEA5-4861EC5A58DC-DataSet.json' | ConvertFrom-Json -Depth 99
$dataSetObject.data.inbound.dataSet.dataSourceId = $dataSource.data.inbound.createDataSource.id
$dataSetObject.data.inbound.dataSet.dataSource.id = $dataSource.data.inbound.createDataSource.id
$dataSet = New-CluedInDataSet -Object $dataSetObject.data.inbound.dataSet

$endpointId = $dataSet.data.inbound.createDataSets.id

Write-host "Sending data to data set id '$($endpointId)'"
$jsonBlob = Get-Content -Path './SampleData/sample-people.json' -Raw
$sendResult = Send-CluedInIngestionData -Json $jsonBlob -IngestionEndpoint $endpointId
if ($sendResult.error -eq 'True' ) { throw "Uh oh, we have a throw" }
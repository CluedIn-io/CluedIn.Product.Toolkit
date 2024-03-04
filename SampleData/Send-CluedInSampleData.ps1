# Create Data Source Set
# Create Data Source
# Create Data Set





Connect-CluedInOrganisation -BaseURL 'devcluedin.com' -Organisation 'cluedin'

# admin@devcluedin.com
# Password-01

$dataSourceSet = New-CluedInDataSourceSet -DisplayName 'People Data Set'

$dataSourceParams = @{
    DataSourceSetId = $dataSourceSet.data.inbound
    Name = 'People Data Source'
    SourceType = 'endpoint'
    AuthorID = '389db794-805d-4a28-82c6-da358f0cb63c'
}
$datasource = New-CluedInDataSource @dataSourceParams

New-CluedInDataSet -Object $dataSetObject

$endpointId = '663C2AFA-8A9B-4936-863B-80CE833229C1'

$jsonBlob = Get-Content -Path '/mnt/c/.sandbox/Hoth-Testing/sample-people.json' -Raw
Send-CluedInIngestionData -Json $jsonBlob -IngestionEndpoint $endpointId
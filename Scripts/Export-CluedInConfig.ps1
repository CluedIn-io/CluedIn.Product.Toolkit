<#
    .SYNOPSIS
    Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

    .DESCRIPTION
    Exports ALL configuration from a connected environment to allow migration or transfer of configuration to another.

    It utilises the module 'CluedIn.Product.Toolkit' to facilitate all this.

    .PARAMETER BaseURL
    This is the base url of your clued in instance. If you access CluedIn by https://cluedin.domain.com, the BaseURL is 'domain.com'

    .PARAMETER Organization
    This is the section before your base URL. If you access CluedIn by https://cluedin.domain.com, the Organization is 'cluedin'

    .PARAMETER BackupPath
    This is the location of where to export files

    .PARAMETER SelectVocabularies
    This is a list of vocabularies (along with keys) that automatically get backed up.
    Default value is 'None', but 'All' and guids are accepted in csv format wrapped in a string.

    Example: '66505aa1-bacb-463e-832c-799c484577a8, e257a226-d91c-4946-a8af-85ef803cf55e'

    .PARAMETER SelectDataSets
    This is a list of Data Sets to backup.
    Default value is 'None', but 'All' and ints are accepted in csv format wrapped in a string.

    Example: '1, 2, 3'

    .PARAMETER SelectRules
    This is a list of Rules to backup. It's agnostic as to what type of rules so long as you specify the guid.
    Default value is 'None', but 'All' and guids are accepted in csv format wrapped in a string.

    Example: '66505aa1-bacb-463e-832c-799c484577a8, e257a226-d91c-4946-a8af-85ef803cf55e'

    .PARAMETER SelectExportTargets
    This is a list of Export Targets to backup. It supports All, None, and csv format of the Id's

    .PARAMETER SelectStreams
    This is a list of Streams to backup. It supports All, None, and csv format of the Id's

    .PARAMETER SelectGlossaries
    This is what Glossaries to export. It supports All, None, and csv format of the Id's.
    It will export all Glossary terms along with it as well.

    .PARAMETER SelectCleanProjects
    Specifies what Clean Projects to export. It supports All, None, and csv format of the Id's

    .PARAMETER IncludeSupportFiles
    Exports a transcript along with the produced JSON files for CluedIn support to use to diagnose any issues relating to migration.

    .EXAMPLE
    PS> ./Export-CluedInConfig.ps1 -BaseURL 'cluedin.com' -Organization 'dev'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseURL,
    [Parameter(Mandatory)][Alias('Organisation')][string]$Organization,
    [Parameter(Mandatory)][string]$BackupPath,
    [switch]$UseHTTP,
    [switch]$BackupAdminSettings,
    [string]$SelectVocabularies = 'None',
    [string]$SelectDataSets = 'None',
    [string]$SelectRules = 'None',
    [string]$SelectExportTargets = 'None',
    [string]$SelectStreams = 'None',
    [string]$SelectGlossaries = 'None',
    [string]$SelectCleanProjects = 'None',
    [switch]$IncludeSupportFiles
)

if ($IncludeSupportFiles) {
    $tempExportDirectory = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath (Get-Date -Format "yyyyMMdd_HHmmss_clue\din")
    $supportFile = Join-Path -Path $tempExportDirectory -ChildPath ('transcript_{0}.txt' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
    New-Item -Path $tempExportDirectory -ItemType Directory | Out-Null

    Write-Host "INFO: Dumping support files"
    Start-Transcript -Path $supportFile | Out-Null
}

Write-Verbose "Importing modules"
Import-Module "$PSScriptRoot/../Modules/CluedIn.Product.Toolkit"

Write-Host "INFO: Connecting to 'https://$Organization.$BaseURL'"
Connect-CluedInOrganization -BaseURL $BaseURL -Organization $Organization -UseHTTP:$UseHTTP

Write-Host "INFO: Starting backup"

# Settings
$generalPath = Join-Path -Path $BackupPath -ChildPath 'General'
if (!(Test-Path -Path $generalPath -PathType Container)) { New-Item $generalPath -ItemType Directory | Out-Null }

Write-Host "INFO: Exporting Admin Settings" -ForegroundColor 'Green'
if ($BackupAdminSettings) {
    Get-CluedInAdminSetting | Out-JsonFile -Path $generalPath -Name 'AdminSetting'
}

# Data Source Sets
$path = Join-Path -Path $BackupPath -ChildPath 'Data/SourceSets'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }

Write-Host "INFO: Exporting Data Sources and Sets" -ForegroundColor 'Green'
$dataSourceSets = Get-CluedInDataSourceSet
$dataSourceSets | Out-JsonFile -Path $path -Name 'DataSourceSet'

# Data Sources (Backup occurs during data set run only)
$dataSourcePath = Join-Path -Path $BackupPath -ChildPath 'Data/Sources'
if (!(Test-Path -Path $dataSourcePath -PathType Container)) { New-Item $dataSourcePath -ItemType Directory | Out-Null }

$dataSources = $dataSourceSets.data.inbound.dataSourceSets.data.datasources
$dataSourceBackup = @{}

# Data Sets and Annotations
$path = Join-Path -Path $BackupPath -ChildPath 'Data/Sets'
if (!(Test-Path -Path $path -PathType Container)) { New-Item $path -ItemType Directory | Out-Null }

$dataSetIds = switch ($SelectDataSets) {
    'All' { $dataSources.dataSets.id }
    'None' { $null }
    default { ($SelectDataSets -Split ',').Trim() }
}

foreach ($id in $dataSetIds) {
    Write-Verbose "Processing id: $id"
    $set = Get-CluedInDataSet -id $id
    if ((!$?) -or ($set.errors)) { Write-Warning "Data Set Id '$id' was not found. This won't be backed up"; continue }

    $dataSourceId = $set.data.inbound.dataSet.dataSourceId
    $dataSource = Get-CluedInDataSource -Id $dataSourceId

    if (!($dataSource.data.inbound.dataSource)) { Write-Warning "Data Source Id '$dataSourceId' was not found. This won't be backed up"; continue }

    # Caching of exports to avoid duplicated work.
    if (!$dataSourceBackup[$dataSourceId]) {
        Write-Host "Exporting Data Source Id: $dataSourceId" -ForegroundColor 'Cyan'
        $dataSource | Out-JsonFile -Path $dataSourcePath -Name ('{0}-DataSource' -f $dataSourceId)
        $dataSourceBackup[$dataSourceId] = $true
    }

    Write-Host "Exporting Data Set: '$($set.data.inbound.dataSet.name) ($id)'" -ForegroundColor 'Cyan'
    $set | Out-JsonFile -Path $path -Name ('{0}-DataSet' -f $id)

    if ($set.data.inbound.dataSet.dataSource.type -eq 'file') {
        Get-CluedInDataSetContent -id $id | Out-JsonFile -Path $path -Name ('{0}-DataSetContent' -f $id)
    }

    $annotationId = $set.data.inbound.dataSet.annotationId
    switch ($annotationId) {
        $null { Write-Warning "No annotation detected. Skipping export of annotations" }
        default {
            Write-Host "Exporting Annotation" -ForegroundColor 'Cyan'
            Get-CluedInAnnotations -id $annotationId | Out-JsonFile -Path $path -Name ('{0}-Annotation' -f $id)
        }
    }
}

# Vocabulary
$dataCatalogPath = Join-Path -Path $BackupPath -ChildPath 'DataCatalog'
$vocabPath = Join-Path -Path $dataCatalogPath -ChildPath 'Vocab'
if (!(Test-Path -Path $vocabPath -PathType Container)) { New-Item $vocabPath -ItemType Directory | Out-Null }

$vocabKeysPath = Join-Path -Path $dataCatalogPath -ChildPath 'Keys'
if (!(Test-Path -Path $vocabKeysPath -PathType Container)) { New-Item $vocabKeysPath -ItemType Directory | Out-Null }

if ($SelectVocabularies -ne 'None') {
    $vocabularies = Get-CluedInVocabulary -IncludeCore
    Write-Host "INFO: Exporting Vocabularies and Keys" -ForegroundColor 'Green'
}

$vocabularyIds = switch ($SelectVocabularies) {
    'All' {
        $null # All not supported at the moment
        #($vocabularies.data.management.vocabularies.data | Where-Object {$_.isCluedInCore -eq $False}).vocabularyId
    }
    'None' { $null }
    default { ($SelectVocabularies -Split ',').Trim() }
}

foreach ($id in $vocabularyIds) {
    # Vocab
    if(Test-IsGuid $id)
    {
        $vocab = Get-CluedInVocabularyById -Id $id

        if ((!$?) -or ($vocab.errors)) {    
            Write-Warning "Id '$id' was not found. This won't be backed up"; 
            continue 
        }
    } else {
        $found = $false
        foreach($vocabulary in $vocabularies.data.management.vocabularies.data) {
            if(($vocabulary.vocabularyName -eq $id) -and ($vocabulary.isCluedInCore -eq $False))
            {
                $vocab = Get-CluedInVocabularyById -Id $vocabulary.vocabularyId
                $id = $vocabulary.vocabularyId
                $found = $true

                Write-Verbose "$($vocabulary.vocabularyId) maps to $($vocabulary.vocabularyName)"
                break
            }
        }

        if($found -eq $false)
        {   
            Write-Warning "Vocabulary '$id' was not found. This won't be backed up"; 
            continue 
        }
    }
    

    Write-Host "Exporting Vocabulary: '$($vocab.data.management.vocabulary.vocabularyName) ($id)'" -ForegroundColor 'Cyan'
    $vocab | Out-JsonFile -Path $vocabPath -Name $id

    # Keys
    $vocabKey = Get-CluedInVocabularyKey -Id $id
    if ((!$?) -or ($vocabKey.errors)) { Write-Warning "Id '$id' was not found. This won't be backed up"; continue }

    $keys = $vocabKey.data.management.vocabularyKeysFromVocabularyId.data.displayName
    $keys = ($keys.ForEach({'[{0}]' -f $_})) -Join ', '
    Write-Host "Exporting Keys: $keys" -ForegroundColor 'Cyan'
    $vocabKey | Out-JsonFile -Path $vocabKeysPath -Name $id
}

# Rules
Write-Host "INFO: Exporting Rules" -ForegroundColor 'Green'
$rulesPath = Join-Path -Path $BackupPath -ChildPath 'Rules'
$dataPartRulesPath = Join-Path -Path $rulesPath -ChildPath 'DataPart'
$survivorshipRulesPath = Join-Path -Path $rulesPath -ChildPath 'Survivorship'
$goldenRecordsRulesPath = Join-Path -Path $rulesPath -ChildPath 'Entity' # Golden Records
if (!(Test-Path -Path $rulesPath -PathType Container)) {
    New-Item $dataPartRulesPath -ItemType Directory | Out-Null
    New-Item $survivorshipRulesPath -ItemType Directory | Out-Null
    New-Item $goldenRecordsRulesPath -ItemType Directory | Out-Null
}

$ruleIds = @()
switch ($SelectRules) {
    'All' {
        foreach ($i in @('Survivorship', 'DataPart', 'Entity')) {
            $rules = Get-CluedInRules -Scope $i
            if ($rules.data.management.rules.data) { $ruleIds += $rules.data.management.rules.data.id }
        }
    }
    'None' { $null }
    default { $ruleIds = ($SelectRules -Split ',').Trim() }
}

foreach ($id in $ruleIds) {
    $rule = Get-CluedInRules -Id $id
    $ruleObject = $rule.data.management.rule
    $rule | Out-JsonFile -Path (Join-Path -Path $rulesPath -ChildPath $ruleObject.scope) -Name $id
}

# Export Targets
Write-Host "INFO: Exporting Export Targets (Connectors)" -ForegroundColor 'Green'
$exportTargetsPath = Join-Path -Path $BackupPath -ChildPath 'ExportTargets'
if (!(Test-Path -Path $exportTargetsPath -PathType Container)) { New-Item $exportTargetsPath -ItemType Directory | Out-Null }

switch ($SelectExportTargets) {
    'All' {
        $exportTargets = Get-CluedInExportTargets
        [array]$exportTargetsId = $exportTargets.data.inbound.connectorConfigurations.configurations.id
    }
    'None' { $null }
    default { $exportTargetsId = ($SelectExportTargets -Split ',').Trim() }
}

foreach ($id in $exportTargetsId) {
    $exportTargetConfig = Get-CluedInExportTarget -Id $id
    $exportTargetConfig | Out-JsonFile -Path $exportTargetsPath -Name $id
}

# Steams
Write-Host "INFO: Exporting Streams" -ForegroundColor 'Green'
$exportStreamsPath = Join-Path -Path $BackupPath -ChildPath 'Streams'
if (!(Test-Path -Path $exportStreamsPath -PathType Container)) { New-Item $exportStreamsPath -ItemType Directory | Out-Null }

switch ($SelectStreams) {
    'All' {
        $streams = Get-CluedInStreams
        [array]$streamsId = $streams.data.consume.streams.data.id
    }
    'None' { $null }
    default { $streamsId = ($SelectStreams -Split ',').Trim() }
}

foreach ($id in $streamsId) {
    $streamConfig = Get-CluedInStream -Id $id
    if ($streamConfig.errors) {
        Write-Warning "Cannot export StreamId '$id'. This is common if permissions are missing on the export target."
        Write-Error "Error: $($streamConfig.errors.message)"
        continue
    }
    $streamConfig | Out-JsonFile -Path $exportStreamsPath -Name $id
}

# Glossaries
Write-Host "INFO: Exporting Glossaries" -ForegroundColor 'Green'
$glossaryPath = Join-Path -Path $BackupPath -ChildPath 'Glossaries'
if (!(Test-Path -Path $glossaryPath -PathType Container)) { New-Item $glossaryPath -ItemType Directory | Out-Null }

switch ($SelectGlossaries) {
    'All' {
        $glossaries = Get-CluedInGlossary
        [array]$glossaryIds = $glossaries.data.management.glossaryCategories.id
    }
    'None' { $null }
    default { $glossaryIds = ($SelectGlossaries -Split ',').Trim() }
}

foreach ($glossaryId in $glossaryIds) {
    $glossaryExportPath = Join-Path -Path $glossaryPath -ChildPath $glossaryId
    if (!(Test-Path -Path $glossaryExportPath -PathType Container)) { New-Item $glossaryExportPath -ItemType Directory | Out-Null }

    # Glossary
    $glossaryConfig = Get-CluedInGlossary -Id $glossaryId
    if ($glossaryConfig.errors) {
        Write-Warning "Received error '$($glossaryConfig.errors.message)'. Skipping id '$glossaryId'."
        continue
    }
    $glossaryConfig | Out-JsonFile -Path $glossaryExportPath -Name ('{0}-Glossary' -f $glossaryId)

    # Glossary Terms
    $glossaryTerms = Get-CluedInGlossaryTerms -GlossaryId $glossaryId
    $glossaryTermsIds = $glossaryTerms.data.management.glossaryTerms.data.id

    # Glossary Term Configuration
    foreach ($termId in $glossaryTermsIds) {
        $glossaryTermConfig = Get-CluedInGlossaryTerm -Id $termId
        $glossaryTermConfig | Out-JsonFile -Path $glossaryExportPath -Name ('{0}-Term' -f $termId)
    }
}

# Clean Projects
Write-Host "INFO: Exporting Clean Projects" -ForegroundColor 'Green'
$cleanProjectsPath = Join-Path -Path $BackupPath -ChildPath 'CleanProjects'
if (!(Test-Path -Path $cleanProjectsPath -PathType Container)) { New-Item $cleanProjectsPath -ItemType Directory | Out-Null }

switch ($SelectCleanProjects) {
    'All' {
        $cleanProjects = Get-CluedInCleanProjects
        [array]$cleanProjectsIds = $cleanProjects.data.preparation.allCleanProjects.projects.id
    }
    'None' { $null }
    default { $cleanProjectsIds = ($SelectCleanProjects -Split ',').Trim() }
}

foreach ($cleanProjectId in $cleanProjectsIds) {
    $cleanProjectConfig = Get-CluedInCleanProject -Id $cleanProjectId
    $cleanProjectConfig | Out-JsonFile -Path $cleanProjectsPath -Name $cleanProjectId
}

Write-Host "INFO: Backup now complete"

if ($IncludeSupportFiles) {
    Write-Verbose "Copying exported JSON to support directory"
    Copy-Item -Path "$BackupPath/*" -Recurse -Destination $tempExportDirectory
    Stop-Transcript | Out-Null

    $zippedArchive = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('cluedin-support_{0}.zip' -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    Compress-Archive -Path "$tempExportDirectory" -DestinationPath "$zippedArchive" -Force
    Remove-Item -Path $tempExportDirectory -Recurse -Force

    Write-Host "Support files ready for sending '$zippedArchive'"
}
#
# Module manifest for module 'CluedIn.Product.Toolkit'
#
# Generated by: Implementation
#
# Generated on: 25/10/2023
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'CluedIn.Product.Toolkit.psm1'

# Version number of this module.
ModuleVersion = '0.0.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '68438eac-e3d7-434d-9dca-963b8e3d1b05'

# Author of this module
Author = 'Implementation'

# Company or vendor of this module
CompanyName = 'CluedIn'

# Copyright statement for this module
Copyright = '(c) CluedIn. All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Connect-CluedInOrganisation', 'Get-CluedInAdminSetting',
               'Get-CluedInAnnotations', 'Get-CluedInAPIToken',
               'Get-CluedInExportTargets', 'Get-CluedInCurrentOrganisation',
               'Get-CluedInDataSet', 'Get-CluedInDataSetContent',
               'Get-CluedInDataSource', 'Get-CluedInDataSourceSet',
               'Get-CluedInEntityType', 'Get-CluedInGlossary',
               'Get-CluedInGlossaryTerms', 'Get-CluedInMapping', 'Get-CluedInMe',
               'Get-CluedInOrganisationFeatures', 'Get-CluedInRules',
               'Get-CluedInStreams', 'Get-CluedInUsers', 'Get-CluedInVocabulary',
               'Get-CluedInVocabularyById', 'Get-CluedInVocabularyKey',
               'New-CluedInAnnotation', 'New-CluedInAPIToken', 'New-CluedInDataSet',
               'New-CluedInDataSetMapping', 'New-CluedInDataSource',
               'New-CluedInDataSourceSet', 'New-CluedInEdgeMapping',
               'New-CluedInEntityType', 'New-CluedInGlossary',
               'New-CluedInGlossaryTerm', 'New-CluedInRule', 'New-CluedInVocabulary',
               'New-CluedInVocabularyKey', 'Out-JsonFile',
               'Send-CluedInIngestionData', 'Set-CluedInAdminSettings',
               'Set-CluedInAnnotation', 'Set-CluedInAnnotationEntityCodes',
               'Set-CluedInRule', 'Set-CluedInDataSourceConfiguration',
               'Set-CluedInVocabulary', 'Set-CluedInVocabularyKey',
               'Enable-CluedInVocabulary', 'Set-CluedInDataSetMapping',
               'Remove-CluedInDataSetMapping', 'Rename-CluedInVocabularyKey',
               'Set-CluedInVocabularyKeyMapping', 'New-CluedInStream',
               'Set-CluedInStream', 'Get-CluedInStream'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}


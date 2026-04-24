# CluedIn.Product.Toolkit

A toolkit to work with the CluedIn product utilising GraphQL query language.

This toolkit is provided by CluedIn to assist with environment switching. Please note that it is not included within the CluedIn license.

## Contents

- [Requirements](#requirements)
- [Supported Resources](#supported-resources)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Scripts](#scripts)
  - [Export-CluedInConfig.ps1](#export-cluedinconfigps1)
  - [Import-CluedInConfig.ps1](#import-cluedinconfigps1)
- [Azure DevOps Pipeline](#azure-devops-pipeline)
- [Notes](#notes)

## Requirements

- PowerShell Core (7+). Works on both Windows and Linux versions of `pwsh`.
- Network access from the host running the toolkit to the CluedIn instance(s) involved.

## Supported Resources

The toolkit can export and import the following CluedIn resources:

| Resource | Export Parameter | Notes |
| --- | --- | --- |
| Admin Settings | `-BackupAdminSettings` | Switch parameter. Always restored on import when present in the backup. |
| Data Source Sets & Data Sets | `-SelectDataSets` | Data source sets are exported alongside their data sets. Archived data sets are excluded. |
| Vocabularies & Vocabulary Keys | `-SelectVocabularies` | `All` is **not** supported here to avoid exporting the core vocabularies shipped with CluedIn (which may contain thousands of keys). |
| Rules | `-SelectRules` | Agnostic to rule type — provide the GUIDs. |
| Export Targets | `-SelectExportTargets` | |
| Streams | `-SelectStreams` | |
| Glossaries & Glossary Terms | `-SelectGlossaries` | Terms are exported along with their parent glossary. |
| Clean Projects | `-SelectCleanProjects` | |
| Deduplication Projects | `-SelectDeduplicationProjects` | |
| Manual Data Entry Projects | `-SelectManualDataEntryProjects` | |

Each `Select...` parameter accepts:

- `None` (default) — nothing of that type is exported.
- `All` — export every instance of that resource (not supported for `SelectVocabularies`).
- A comma-separated list of Ids/GUIDs/names wrapped in a string, e.g. `'66505aa1-bacb-463e-832c-799c484577a8, e257a226-d91c-4946-a8af-85ef803cf55e'`.

There is no hard-and-fast export order — you can mix and match the `Select...` parameters as needed, export a few at a time, or export everything in one run.

## Installation

This toolkit can be used both locally and from an automated pipeline.

1. Open a `pwsh` session.
1. Import the module:
   ```powershell
   Import-Module /path/to/CluedIn.Product.Toolkit
   ```
1. You are now ready to use the functions or scripts.

To list available functions, run `Get-Command -Module CluedIn.Product.Toolkit`.
To see how to use an individual function, run `Get-Help -Name <functionName>`.

### Authentication

If you plan on calling the individual functions (as opposed to the bundled scripts), run `Connect-CluedInOrganization` before calling any function — otherwise they will fail to produce results.

> **Note:** The functions rely on a JWT that by default lasts 60 minutes. If it expires, run `Connect-CluedInOrganization -Force` to refresh.

The bundled `Export-CluedInConfig.ps1` and `Import-CluedInConfig.ps1` scripts will call `Connect-CluedInOrganization` themselves, so you don't need to connect beforehand when using them.

## Quick Start

Export some rules and streams from a source environment:

```powershell
./Scripts/Export-CluedInConfig.ps1 `
    -BaseURL 'cluedin.com' `
    -Organization 'source' `
    -BackupPath 'C:\backups\cluedin' `
    -SelectRules 'All' `
    -SelectStreams 'All'
```

Validate the produced JSON files under `-BackupPath` and make any adjustments if necessary.

We recommend starting a fresh PowerShell session (so any cached tokens/variables are cleared) and then importing into the destination:

```powershell
./Scripts/Import-CluedInConfig.ps1 `
    -BaseURL 'cluedin.com' `
    -Organization 'destination' `
    -RestorePath 'C:\backups\cluedin'
```

The import restores everything found under `RestorePath` and handles drift — if it matches an existing item that has been updated, it is reconciled back to the values in the backup.

Validate the result by logging into the destination URL and checking that the resources have been transferred across.

## Scripts

### Export-CluedInConfig.ps1

Exports the selected configuration from a connected environment as a set of JSON files.

By default every `Select...` parameter is `None`. Running the script without any of them will connect to the environment and only run the default settings pass — no resources will be exported.

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `BaseURL` | string | Yes | — | Base URL of the CluedIn instance. For `https://cluedin.domain.com`, the BaseURL is `domain.com`. |
| `Organization` | string | Yes | — | Organization portion of the URL. For `https://cluedin.domain.com`, the Organization is `cluedin`. Alias: `Organisation`. |
| `BackupPath` | string | Yes | — | Location where the export files will be written. |
| `UseHTTP` | switch | No | `$false` | Use HTTP instead of HTTPS. Required for 'Home' environments. |
| `BackupAdminSettings` | switch | No | `$false` | Include admin settings in the export. |
| `SelectVocabularies` | string | No | `None` | Vocabularies (and their keys) to export. CSV of GUIDs or names. `All` is **not** supported. |
| `SelectDataSets` | string | No | `None` | Data Sets to export. `None`, `All`, or CSV of Ids. |
| `SelectRules` | string | No | `None` | Rules to export (any rule type). `None`, `All`, or CSV of GUIDs. |
| `SelectExportTargets` | string | No | `None` | Export Targets to export. `None`, `All`, or CSV of Ids. |
| `SelectStreams` | string | No | `None` | Streams to export. `None`, `All`, or CSV of Ids. |
| `SelectGlossaries` | string | No | `None` | Glossaries to export (terms are included automatically). `None`, `All`, or CSV of Ids. |
| `SelectCleanProjects` | string | No | `None` | Clean Projects to export. `None`, `All`, or CSV of Ids. |
| `SelectDeduplicationProjects` | string | No | `None` | Deduplication Projects to export. `None`, `All`, or CSV of Ids. |
| `SelectManualDataEntryProjects` | string | No | `None` | Manual Data Entry Projects to export. `None`, `All`, or CSV of Ids. |
| `IncludeSupportFiles` | switch | No | `$false` | Wraps the JSON export with a transcript and produces a ZIP for CluedIn support to diagnose migration issues. |

**Example**

```powershell
./Scripts/Export-CluedInConfig.ps1 `
    -BaseURL 'cluedin.com' `
    -Organization 'dev' `
    -BackupPath 'C:\backups\cluedin' `
    -SelectVocabularies 'organization,user' `
    -SelectRules 'All' `
    -SelectStreams 'All' `
    -BackupAdminSettings
```

### Import-CluedInConfig.ps1

Restores a previously exported configuration into the connected environment. No `Select...` parameters are needed — everything found in `RestorePath` is imported.

| Parameter | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `BaseURL` | string | Yes | — | Base URL of the destination CluedIn instance. |
| `Organization` | string | Yes | — | Organization portion of the destination URL. Alias: `Organisation`. |
| `RestorePath` | string | Yes | — | Path to the folder produced by `Export-CluedInConfig.ps1`. |
| `UseHTTP` | switch | No | `$false` | Use HTTP instead of HTTPS. Required for 'Home' environments. |
| `IncludeSupportFiles` | switch | No | `$false` | Wraps the run with a transcript and produces a ZIP for CluedIn support. |

**Example**

```powershell
./Scripts/Import-CluedInConfig.ps1 `
    -BaseURL 'cluedin.com' `
    -Organization 'prod' `
    -RestorePath 'C:\backups\cluedin'
```

## Azure DevOps Pipeline

The Azure DevOps pipeline method works in the same way as the local version, but it runs on an ADO Build Agent instead. The build agent must be able to reach the CluedIn instances, otherwise it will fail.

We have provided sample pipelines for backup, restore, and a combined version of the two called *transfer*. These are boilerplate samples and will require your team to adjust them to your needs — they are a guide on how to set them up and will not work without additional work on your end.

Please refer to [`README-Pipelines.md`](README-Pipelines.md).

## Notes

- If you are using a 'Home' environment, append port `:8888` to the end of the base URL and also pass `-UseHTTP`, since HTTPS isn't supported in home environments by default.
- Please ensure rule names are unique to avoid lookup conflicts.
- After an import, validate by logging into the destination URL and confirming everything has been transferred across.

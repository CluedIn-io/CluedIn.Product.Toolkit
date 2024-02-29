# CluedIn.Product.Toolkit

A toolkit to work with the CluedIn product utilising GraphQL query language.

## Installation

It is possible to use this toolkit locally, as well as having it automated via a pipeline. 

We support PowerShell Core (7+) only, and it will work on both Windows and Linux versions of `pwsh`

### Local Usage

Using this toolkit is very simple from a local usage perspective. We simply import the module, and run either the functions or scripts depending on what is trying to be achieved.

1. Open up a `pwsh` and import the module. If doing this locally, you can simply do:
    `Import-Module /path/to/CluedIn.Product.Toolkit`
1. Once imported, we are ready to use the Functions or the Scripts.
1. If using the functions, please ensure you run `Connect-CluedInOrganisation` before running any function, as it will fail to produce any results.

    **Note**: The functions rely on a JWToken being obtained. This token by default will last 60 minutes only. If it loses connection, you'll need to run `Connect-CluedInOrganisation -Force` to refresh.
    
1. Once you have connected successfully, you can then run any function within the toolkit. 

To list out functions availabe, you can run `Get-Command -Module CluedIn.Product.Toolkit`.
To see how to use the functions, you can run `Get-Help -Name ${functionName}`

Included in the toolkit are 2 main scripts.
- `Export-CluedInConfig.ps1`
- `Import-CluedInConfig.ps1`

Both of these will work so long as you have the toolkit imported. It will attempt to connect when you run them, so it's not necessary to run `Connect-CluedInOrganisation` beforehand.

The way it works is `Export-CluedInConfig.ps1` will export the configuration as json files.
You must specify `BaseURL`, `Organisation`, and `BackupPath`. There are then a few additional parameters to define what to export. These begin with `Select` followed by the type of resource to export. (ie. `SelectDataSets`).

**Note**: If you are using this on a 'Home' environment, you'll need to append port 8888 (`:8888`) to the end of the base URL and also use `-UseHTTP` as HTTPS isn't supported in home environments by default.

By default, all these will be set to `None`, meaning if you were to run the script without specifying what to export, you will export nothing. There is no hard and fast rule as to export order. You can export a few bits at once, you can export everything, and mix and match. Another supported value is `All` which will work for all Select parameters except for `SelectVocabularies`. This is because CluedIn by default comes shipped with Core Vocabularies which may contain thousands of vocabulary keys. This is not ideal in an export scenario.

Once you have exported the configuration, you can validate these by navigating to the specified `BackupPath` and seeing the files in `json` format. You can make any adjustments here if necessary, or simply validate it's what you're expecting.

When you're ready, you can then run `Import-CluedInConfig.ps1`. We recommend starting a new PowerShell session before doing this so that any potential variables are wiped clean beforehand.

The import simply needs to know the destination and the folder to restore. There's nothing you need to specify as it'll restore everything in the `RestoreFolder`. The import process will cover drift as well. If it matches an existing field that may have been updated, it'll ensure it's set to the correct values.

You can then validate by logging into the destination URL and ensuring everything has been transferred across.

### Azure DevOps Pipeline

The Azure DevOps pipeline method works in the same way as the local version, but it runs on an ADO Build Agent instead. This build agent must be able to reach the CluedIn instances, otherwise it will fail.

We have provided sample pipelines for backup, restore, and a combined version of the two called transfer.

These are boilerplate samples, and will require your team to adjust to your needs. They're just a guide on how to set them up and will not work without additional work on your end. 

Please refer to `README-Pipelines.md`.

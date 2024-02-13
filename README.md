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
1. 

### Azure DevOps Pipeline
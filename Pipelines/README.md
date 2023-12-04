# Introduction
This folder contains sample pipelines on how you can automate the backup or transfer of your CluedIn configuration.
It also has the ability to capture the backup the configuration (json files) to an external git repository.

# Prerequisites
1. Access to Azure DevOps pipelines with the ability to create a new pipeline.
2. An empty git repository to use as backup destination. We don't recommend using the same repo the pipeline and code exists in.
3. The ADO agent must be able to access the frontend of your CluedIn instance(s).

# Process
## ADO
Because authentication is required to invoke the backup tasks, we'll need to securely store credentials and expose as environmental variables on the ADO build agent.

We recommend using ADO Library which you can then link to Azure Key Vault of your choice.

For this example, we'll just be using the native ADO library.

### Service Account
Please follow the script 'New-CluedInServiceAccount.ps1' located in the scripts folder. You will need to read this file as it will create a service account and advise what Role to create once setup.

### Secrets
1. In Azure DevOps, navigate to your Project and then Pipelines > Library
2. Create a new Variable Group called 'CluedIn-Authentication'.
3. Create 4 variables
   * source-cluedin-username: This should be an account on the source CluedIn that has enough permission.
   * source-cluedin-password: This is the password for the above account, please ensure you change the type to secret so it masks the password. This is controlled by the lock to the right of the textbox.
   * destination-cluedin-username: This should be an account on the destination CluedIn that has enough permission.
   * destination-cluedin-password: This is the password for the above account, please ensure you change the type to secret so it masks the password. This is controlled by the lock to the right of the textbox.
4. Click on [Save] at the top.

### Pipeline
1. In Azure DevOps, navigate to your Project and then Pipelines > Pipelines
2. Click on **All** at the top
3. Find/Create the folder (or location) you'd like to store this automated pipeline and then click on [ **New pipeline** ]
4. Depending where you have stored the CluedIn backup and transfer pipeline sample, navigate to the repo and select it.
5. Update the name of the pipeline as it'll inherit the default. This is used as part of the git commit message when pushing to an external git repository.

### Pipeline Alterations
With this now setup, we need to make a few adjustments to the pipeline before it is useable.

1. Navigate to the git repository where the pipeline is located
2. You will need to update the following:

   * the variable group name, and variable values to match what is in your ADO/KV if they have deviated from the above.
   * Repositories Type, Endpoint, and Name. Update '- repository: backupRepo' to match your destination. You will also need to update 'workingDirectory: $(System.DefaultWorkingDirectory)/registry' to match the registry name of where your repo resides.

### First run
1. Click on [Run Pipeline]
2. Fill in parameters:
   * **CluedIn Base URL (Source)**: This is in the format of customer.com without http(s)://
   * **CluedIn Organisation (Source)**: This is the first part of your cluedin environment. If you access your environment using https://cluedin.customer.com, it will just simply be 'cluedin'.
   * **CluedIn Base URL (Destination)**: This is in the format of customer.com without http(s)://
   * **CluedIn Organisation (Destination)**: This is the first part of your cluedin environment. If you access your environment using https://cluedin.customer.com, it will just simply be 'cluedin'.
   * **CluedIn Environment Version**: Unfortunately due to current limitations, this needs to be specified in the format on 2023.07 for the current environment we're backing up.
   * **Vocabularies (guid, csv)**: Accepted values are 'None', or the guids seperated by a comma (,). All will not work for this one.
   * **Data Sources (int, csv)**: Accepted values are 'All', 'None', or Interger value seperated by a comma (,).
   * **Data Sets (guid, csv)**: Accepted values are 'All', 'None', or guids seperated by a comma (,).
   * **Rules (guid, csv)**: Accepted values are 'All', 'None', or guids seperated by a comma (,).
   * **Push to repo**: If set to true, it will push your configuration json files to the specified git repository in the pipeline.
3. When ready, click on [**Run**]

This will take a couple minutes to run. Once completed, you should be able to view the updates in the destination server.
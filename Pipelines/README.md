# Introduction
This pipeline is a sample pipeline on how you can automate the backup of your CluedIn instance to take a copy of all configuration, export it, and then push to a git repository.

For this example, we will be using GitHub as our git repository destination, but you can use any repository of your choice for source control.

# Prerequisites
1. Access to Azure DevOps pipelines with the ability to create a new pipeline.
2. An empty git repository to use as backup destination. We don't recommend using the same repo the pipeline and code exists in, but the choice is yours.
3. The ADO agent must be able to access the frontend of your CluedIn instance.

# Process
## ADO
Because authentication is required to invoke the backup tasks, we'll need to securely store credentials and expose as environmental variables on the agent.

We recommend using ADO Library which you can then link to Azure Key Vault of your choice.

For this example, we'll just be using the native library.

### Secrets
1. In Azure DevOps, navigate to your Project and then Pipelines > Library
2. Create a new Variable Group called 'CluedIn Connection' or something appropriate to your setup.
3. Create 2 variables
   * cluedin.username: This should be an account on CluedIn that has enough permission
   * cluedin.password: This is the password for the above account, please ensure you change the type to secret so it masks the password. This is controlled by the lock to the right of the textbox.
4. Click on [Save] at the top.

### Pipeline
1. In Azure DevOps, navigate to your Project and then Pipelines > Pipelines
2. Click on **All** at the top
3. Find/Create the folder (or location) you'd like to store this automated pipeline and then click on [ New pipeline ]
4. Depending where you have stored the clued in backup pipeline sample, navigate to the repo and select it so that it can now be used.
5. Update the name of the pipeline as it'll inherit the default. This is used as part of the git commit message.

### First run
With everything now setup, it's time to give it a run.
When we're confident it works without a problem, it's best to update the source pipeline file with default values and a cron schedule.

1. Click on [Run Pipeline]
2. Fill in parameters:
   * **CluedIn Base URL**: This is in the format of customer.com without http(s)://
   * **CluedIn Organisation**: This is the first part of your cluedin environment. If you access your environment using https://cluedin.customer.com, it will just simply be 'cluedin'.
   * *CluedIn Environment Version*: Unfortunately due to current limitations, this needs to be specified in the format on 2023.01.01 for the current environment we're backing up
3. When ready, click on [Run]

This shouldn't take more than a couple minutes to complete and if succesful, you should see the files directly uploaded to your backup git repository
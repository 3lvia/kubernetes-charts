# Scripts

The scripts in this folder are for **testing only**.

They apply the Helm chart directly using `helm upgrade --install`, bypassing the normal CI/CD pipeline and 3lvia CLI. 
This allows you to quickly validate Helm chart changes or deployment configuration without triggering a full deployment workflow.

> **Note:** These scripts should never be used to deploy to production environments.

> **Note:** The image tag is hardcoded im the scripts - update before testing.
    -> you can find the 


# Scripts

The scripts in this folder are for **testing only**.

They apply the Helm chart directly using `helm upgrade --install`, bypassing the normal CI/CD pipeline and 3lvia CLI. 
This allows you to quickly validate Helm chart changes or deployment configuration without triggering a full deployment workflow.

> **Note:** These scripts should never be used to deploy to production environments.

> **Note:** The image tag is hardcoded in the scripts - update before testing.
    -> you can find the image tag
         kubectl get pods -n core
         kubectl describe pod demo-api-XXXXXXXXXXXX -n core
        look for
         Image:          containerregistryelvia.azurecr.io/core/demo-api:1a6495f267bfbfc8bccc6c7f8a39ba44a0a37725-240

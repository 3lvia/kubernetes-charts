# kubernetes-charts
Default charts for kubernetes resources used by Elvia

# development

After making changes to the charts AND changing the version, run
```
helm package elvia-deployment
helm package <name-of-chart>
helm repo index .
git commit
git push
```

# test

Local
```
helm template github-repo -f elvia-deployment/examples/github-repository-team-adder/values_api.yaml elvia-deployment/  --set environment=test --set image.tag=mytag
helm template github-repo -f elvia-deployment/examples/github-repository-team-adder/values_api.yaml elvia-deployment/  --set environment=test --set image.tag=mytag|kubeval --strict --ignore-missing-schemas
```

Remote
```
helm repo add elvia-deployment https://raw.githubusercontent.com/3lvia/kubernetes-charts/master
helm repo update
helm template github-repository-team-adder -f elvia-deployment/examples/github-repository-team-adder/values.yaml elvia-deployment
```

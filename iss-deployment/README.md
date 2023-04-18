# kubernetes-charts
Default charts for kubernetes resources used by iss and adms-extensions

# development

After making changes to the charts AND changing the version, run
```
echo "Endre Chart version i Chart.yaml"
helm package iss-deployment
helm repo index .
git commit
git push
```

# test

Local
```
helm template demo-api -f iss-deployment/examples/demo-api/values.yaml ./  --set environment=test --set image.tag=mytag
```

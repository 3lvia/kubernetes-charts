# kubernetes-charts

Default charts for Kubernetes resources used by Elvia.

## Publishing new charts

Upgrade the version in the charts `Chart.yaml` file.
When pushing to trunk, the charts will automatically packaged and published to the GitHub repository.

## Testing

Unit testing
```sh
helm plugin install https://github.com/helm-unittest/helm-unittest.git
helm unittest elvia-deployment
```

Local
```
helm template github-repo -f elvia-deployment/examples/github-repository-team-adder/values_api.yaml elvia-deployment/  --set environment=test --set image.tag=mytag
# https://github.com/yannh/kubeconform
helm template github-repo -f elvia-deployment/examples/github-repository-team-adder/values_api.yaml elvia-deployment/  --set environment=test --set image.tag=mytag|kubeconform -strict -ignore-missing-schemas -verbose

helm template gridtariff-cache -f elvia-statefulset/examples/gridtariff-cache/values.yaml elvia-statefulset/  --set environment=test --set image.tag=mytag
```

Remote
```
helm repo add elvia-deployment https://raw.githubusercontent.com/3lvia/kubernetes-charts/master
helm repo update
helm template github-repository-team-adder -f elvia-deployment/examples/github-repository-team-adder/values.yaml elvia-deployment --set environment=test --set image.tag=mytag
```

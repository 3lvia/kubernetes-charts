# kubernetes-charts

Default charts for Kubernetes resources used by Elvia.

# Usage
These charts are normally used in combination with Elvias CI/CD templates. See https://github.com/3lvia/core-github-actions-templates for details. 

## Manual installation
```
helm repo add elvia-deployment https://raw.githubusercontent.com/3lvia/kubernetes-charts/master
helm repo update
helm install -n <namespace> <myapp> elvia-deployment/elvia-deployment -f values.yaml
```

## Configuration
To show all options:
```
helm repo add elvia-deployment https://raw.githubusercontent.com/3lvia/kubernetes-charts/master
helm repo update
helm show values elvia-deployment/elvia-deployment
```

### Examples: 
* https://github.com/3lvia/kubernetes-charts/tree/master/elvia-deployment/examples
* https://github.com/3lvia/kubernetes-charts/tree/master/elvia-statefulset/examples
* https://github.com/3lvia/kubernetes-charts/tree/master/iss-deployment/examples

# Development

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
helm template github-repo -f elvia-deployment/examples/demo-api/values.yaml elvia-deployment/  --set environment=test --set image.tag=mytag
# https://github.com/yannh/kubeconform
helm template github-repo -f elvia-deployment/examples/demo-api/values.yaml elvia-deployment/  --set environment=test --set image.tag=mytag|kubeconform -strict -ignore-missing-schemas -verbose

helm template gridtariff-cache -f elvia-statefulset/examples/gridtariff-cache/values.yaml elvia-statefulset/  --set environment=test --set image.tag=mytag
```

Remote
```
helm repo add elvia-deployment https://raw.githubusercontent.com/3lvia/kubernetes-charts/master
helm repo update
helm template github-repository-team-adder -f elvia-deployment/examples/github-repository-team-adder/values.yaml elvia-deployment --set environment=test --set image.tag=mytag
```

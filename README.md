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
* https://github.com/3lvia/kubernetes-charts/tree/master/charts/elvia-job/examples
* https://github.com/3lvia/kubernetes-charts/tree/master/charts/elvia-cronjob/examples
* https://github.com/3lvia/kubernetes-charts/tree/master/iss-deployment/examples

## Pod Security Restricted

The Elvia workload charts default to settings compatible with Linux Pod Security
`restricted`: `allowPrivilegeEscalation: false`, `runAsNonRoot: true`, all Linux
capabilities dropped, and pod-level `seccompProfile.type: RuntimeDefault`.
`readOnlyRootFilesystem` is not required by this policy and is not enabled.

The legacy `iss-deployment` chart is unchanged and does not meet `restricted`
requirements. Do not enforce this policy on its namespaces without a separate
review and migration.

For `elvia-deployment`, `elvia-job` and `elvia-cronjob`, a custom pod
`securityContext` still replaces the default user/group settings. Seccomp defaults
to `RuntimeDefault` even with a custom context; an explicit `Localhost` profile
is preserved and must be installed on every eligible node. Custom values must
also comply with the policy: for example, UID 0, `runAsNonRoot: false`,
`seccompProfile.type: Unconfined`, and unsafe sysctls are rejected by Kubernetes.
Custom `volumes` must use allowed types, such as `configMap`, `secret`, `emptyDir`,
`projected`, `csi` or `persistentVolumeClaim`; `hostPath` is not allowed.

### Rollout Considerations

- Upgrade chart releases before enforcing the policy on their namespaces.
	These charts do not manage Namespace resources or their labels.
- Deployment sidecars and StatefulSets now drop all
	capabilities. Images that need capabilities (for example, to bind privileged
	ports on some runtimes) may fail. Prefer unprivileged ports; `restricted` only
	permits adding back `NET_BIND_SERVICE`, which these charts do not add.
	StatefulSets already used UID 1001 and now explicitly
	require non-root execution as well.
- Check admission-injected sidecars and init containers too. In particular,
	Istio's iptables init container commonly requires root/`NET_ADMIN`, which is
	incompatible with `restricted`; an Istio CNI setup may be needed. Chart tests
	cannot validate containers injected by the cluster.
- Existing Pods are not evicted when the label is set, but replacement Pods
	must comply. Existing Jobs have immutable pod templates and may need to be
	recreated; check retained CronJob Jobs as well.
- First enable `pod-security.kubernetes.io/warn=restricted` and
	`pod-security.kubernetes.io/audit=restricted`, and validate real workloads in
	a test namespace before setting `pod-security.kubernetes.io/enforce=restricted`.
	Pin the corresponding `*-version` labels to your Kubernetes minor version to
	avoid policy changes on cluster upgrades. Admission checks do not prove that
	the application will start; verify readiness, logs and volume permissions too.

# Development

## Publishing new charts

Upgrade the version in the charts `Chart.yaml` file.
When pushing to trunk, the charts will automatically packaged and published to the GitHub repository.

`elvia-job` and `elvia-cronjob` use the shared `elvia-job-common` library chart. After changing the dependency or the shared library, update the vendored dependencies for both charts:
```sh
helm dependency update charts/elvia-job
helm dependency update charts/elvia-cronjob
```

Commit the resulting `Chart.lock` files and `charts/elvia-job-common-*.tgz` files. The publishing workflow packages the charts directly and expects these dependencies to already be present.

## Testing

Unit testing
```sh
helm plugin install https://github.com/helm-unittest/helm-unittest.git
helm unittest charts/elvia-deployment charts/elvia-statefulset charts/elvia-job charts/elvia-cronjob
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

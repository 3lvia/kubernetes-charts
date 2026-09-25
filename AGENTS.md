# Agent guidance

## Repository structure

- Helm charts live under `charts/`.
- `elvia-job` is the one-off Job chart.
- `elvia-cronjob` is the scheduled CronJob chart.
- `elvia-job-common` is a Helm library chart shared by both charts.

## Dependency workflow

When changing `elvia-job-common`, update and vendor the dependency for both consumer charts:

```sh
helm dependency update charts/elvia-job
helm dependency update charts/elvia-cronjob
```

Commit the resulting `Chart.lock` files and vendored `charts/elvia-job-common-*.tgz` files. The publish workflow packages charts directly and does not update dependencies first.

## Versioning

- Bump `elvia-job` for changes to the Job chart.
- Bump `elvia-cronjob` for changes to the CronJob chart.
- Bump `elvia-job-common` and both consumer charts when shared templates change.
- Use a patch bump for internal refactors that preserve rendered behavior; use minor for new backwards-compatible chart functionality.

## Validation

Run the focused tests while developing:

```sh
helm dependency build charts/elvia-job
helm dependency build charts/elvia-cronjob
helm lint charts/elvia-job -f charts/elvia-job/ci/demo-job-values.yaml
helm lint charts/elvia-cronjob -f charts/elvia-cronjob/ci/demo-cronjob-values.yaml
helm unittest charts/elvia-deployment charts/elvia-statefulset charts/elvia-job charts/elvia-cronjob
```

Before opening a PR, run `ct lint` using WSL. `ct/bin/ct` is a Linux binary:

```sh
wsl.exe -d Ubuntu -- bash -lc "cd /mnt/c/Users/wr1026/github/3lvia/kubernetes-charts && ./ct/bin/ct lint --config ct.yaml --chart-yaml-schema ct/etc/chart_schema.yaml --lint-conf ct/etc/lintconf.yaml --validate-maintainers=false"
```

## Editing files

New files created on Windows may have CRLF line endings, which `yamllint` rejects. Normalize new chart files to LF in WSL:

```sh
sed -i 's/\r$//' path/to/file
```

Keep `ct.yaml` chart paths prefixed with `charts/`. Add a `ci/*-values.yaml` file for charts whose templates require values, so `ct lint` has valid values to render.

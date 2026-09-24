{{/*
Expand the name of the chart.
*/}}
{{- define "elvia-job.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "elvia-job.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "elvia-job.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elvia-job.labels" -}}
helm.sh/chart: {{ include "elvia-job.chart" . }}
{{ include "elvia-job.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elvia-job.selectorLabels" -}}
app.kubernetes.io/name: {{ include "elvia-job.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "elvia-job.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "elvia-job.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define the image, using containerregistryelvia.azurecr.io as default container registry.

Supports image for any environment:

  image:
    repository: myrepo
    tag: mytag

or environment-specific:

  image:
    sandbox:
      repository: myrepo
      tag: mytag
    dev:
      repository: myrepo
      tag: mytag
    kptest:
      repository: myrepo
      tag: mytag
    test:
      repository: myrepo
      tag: mytag
    prod:
      repository: myrepo
      tag: mytag

*/}}
{{- define "image" -}}
{{- $imagetag := .Values.image.tag }}
{{- $imagerepository := .Values.image.repository }}
{{- if and (eq .Values.environment "sandbox") .Values.image.sandbox }}
{{- $imagerepository = .Values.image.sandbox.repository }}
{{- $imagetag = .Values.image.sandbox.tag }}
{{- end }}
{{- if and (eq .Values.environment "dev") .Values.image.dev }}
{{- $imagerepository = .Values.image.dev.repository }}
{{- $imagetag = .Values.image.dev.tag }}
{{- end }}
{{- if and (eq .Values.environment "kptest") .Values.image.kptest }}
{{- $imagerepository = .Values.image.kptest.repository }}
{{- $imagetag = .Values.image.kptest.tag }}
{{- end }}
{{- if and (eq .Values.environment "test") .Values.image.test }}
{{- $imagerepository = .Values.image.test.repository }}
{{- $imagetag = .Values.image.test.tag }}
{{- end }}
{{- if and (eq .Values.environment "prod") .Values.image.prod }}
{{- $imagerepository = .Values.image.prod.repository }}
{{- $imagetag = .Values.image.prod.tag }}
{{- end }}
{{- /* only allow setting image repo if it is not on old deprecated syntax */}}
{{- if and .Values.image.repository (ne .Values.image.repository (printf "containerregistryelvia.azurecr.io/%s-%s" .Values.namespace .Values.name)) }}
{{- .Values.image.repository }}:{{ required (printf "Missing image.tag or image.%s.tag" .Values.environment) $imagetag }}
{{- else }}
{{- printf "containerregistryelvia.azurecr.io/%s/%s" .Values.namespace .Values.name }}:{{ required (printf "Missing image.tag or image.%s.tag" .Values.environment) $imagetag }}
{{- end }}
{{- end }}

{{/*
Find the limits.cpu in millicores, but capped at 50m
*/}}
{{- define "resources.limits.cpu.max50m" -}}
{{- if .Values.resources.limits }}
{{- if .Values.resources.limits.cpu | toString | hasSuffix "m" }}
{{- .Values.resources.limits.cpu  | toString | regexFind "[0-9.]+" | min 50 -}}m
{{- else -}}
{{- mulf .Values.resources.limits.cpu 1000 | min 50 -}}m
{{- end -}}
{{- else if .Values.resources.dev.limits }}
{{- if .Values.resources.dev.limits.cpu | toString | hasSuffix "m" }}
{{- .Values.resources.dev.limits.cpu  | toString | regexFind "[0-9.]+" | min 50 -}}m
{{- else -}}
{{- mulf .Values.resources.dev.limits.cpu 1000 | min 50 -}}m
{{- end -}}
{{- else -}}
{{- fail "Missing resource.limits.cpu" }}
{{- end -}}
{{- end -}}

{{/*
Find the limits.memory in Mi, but capped at 100Mi
*/}}
{{- define "resources.limits.memory.max100Mi" -}}
{{- if .Values.resources.limits }}
{{- if .Values.resources.limits.memory | toString | hasSuffix "Mi" }}
{{- .Values.resources.limits.memory  | toString | regexFind "[0-9.]+" | min 100 -}}Mi
{{- else if .Values.resources.limits.memory | toString | hasSuffix "Gi" }}
{{- .Values.resources.limits.memory  | toString | regexFind "[0-9.]+" | mulf 1000 | min 100 -}}Mi
{{- else -}}
{{- fail "value for resources.limits.memory must be given in Mi or Gi units." }}
{{- end -}}
{{- else if .Values.resources.dev.limits }}
{{- if .Values.resources.dev.limits.memory | toString | hasSuffix "Mi" }}
{{- .Values.resources.dev.limits.memory  | toString | regexFind "[0-9.]+" | min 100 -}}Mi
{{- else if .Values.resources.dev.limits.memory | toString | hasSuffix "Gi" }}
{{- .Values.resources.dev.limits.memory  | toString | regexFind "[0-9.]+" | mulf 1000 | min 100 -}}Mi
{{- else -}}
{{- fail "value for resources.limits.memory must be given in Mi or Gi units." }}
{{- end -}}
{{- else -}}
{{- fail "Missing resource.limits.memory" }}
{{- end -}}
{{- end -}}

{{/*
Shared metadata (name, namespace, labels) used by both Job and CronJob.
*/}}
{{- define "elvia-job.metadata" -}}
name: {{ required "Missing .Values.name" .Values.name }}
namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
{{- if .Values.labels }}
{{- if kindIs "map" .Values.labels }}
labels:
  {{- /* Checks if the provided labels contain any disallowed labels */ -}}
  {{- range $key, $val := .Values.labels }}
    {{- if and (ne $key "repositoryName") (ne $key "commitHash") (ne $key "deployedBy") }}
    {{- fail (printf "%s is not an allowed label. Allowed labels are: repositoryName, commitHash and deployedBy" $key) }}
    {{- end }}
  {{- end }}
  {{- if ((.Values.labels).repositoryName)}}
  repositoryName: {{((.Values.labels).repositoryName)}}
  {{- end }}
  {{- if ((.Values.labels).commitHash)}}
  commitHash: {{((.Values.labels).commitHash)}}
  {{- end }}
  {{- if ((.Values.labels).deployedBy)}}
  deployedBy: {{((.Values.labels).deployedBy)}}
  {{- end }}
{{- else }}
{{- fail ".Values.labels must be a map" }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Shared Job spec (backoffLimit, completions, parallelism and pod template).
Used both as the Job's .spec and as the CronJob's .spec.jobTemplate.spec.
*/}}
{{- define "elvia-job.jobSpec" -}}
backoffLimit: {{ default 6 .Values.backoffLimit }}
completions: {{ default 1 .Values.completions }}
parallelism: {{ default 1 .Values.parallelism }}
template:
  metadata:
    annotations:
      kubectl.kubernetes.io/default-container: {{ required "Missing .Values.name" .Values.name }}
    labels:
      app: {{ required "Missing .Values.name" .Values.name }}
      microservice-type: "job"
      azure.workload.identity/use: "true"
  spec:
    restartPolicy: Never
    serviceAccountName: {{ required "Missing .Values.name" .Values.name }}
    imagePullSecrets:
    {{- if .Values.imagePullSecret }}
    - name: {{ .Values.imagePullSecret }}
    {{- else }}
    - name: containerregistryelvia
    {{- end}}
    {{- if .Values.securityContext }}
    securityContext: {{- toYaml .Values.securityContext | nindent 6 }}
    {{- else }}
    securityContext:
      seccompProfile:
        type: RuntimeDefault
      runAsUser: 1001
      runAsGroup: 1001
      fsGroup: 1001
      supplementalGroups: [1001]
    {{- end }}
    containers:
    - name: {{ required "Missing .Values.name" .Values.name }}
      {{- if .Values.envFrom}}
      envFrom:
      {{- range $envFromKey, $envFromValue := .Values.envFrom }}
      - configMapRef:
          name: {{ required "Missing $envFromValue.name" $envFromValue.name }}
      {{- end }}
      {{- end }}
      env:
      - name: ELVIA_APPLICATION_NAMESPACE
        value: {{ required "Missing .Values.namespace" .Values.namespace }}
      - name: ELVIA_APPLICATION_NAME
        value: {{ required "Missing .Values.name" .Values.name }}
      - name: ELVIA_ENVIRONMENT
        value: {{ required "Missing .Values.environment" .Values.environment }}
      - name: ELVIA_WORKLOAD_IDENTITY_NAME
        value: uai-{{ required "Missing .Values.namespace" .Values.namespace }}-{{ required "Missing .Values.name" .Values.name }}-{{ required "Missing .Values.environment" .Values.environment }}
      - name: OTEL_EXPORTER_OTLP_PROTOCOL
        value: grpc
      - name: OTEL_EXPORTER_OTLP_ENDPOINT
        value: http://otel-collector.monitoring.svc.cluster.local:4317
      - name: OTEL_SERVICE_NAME
        value: {{ required "Missing .Values.name" .Values.name }}
      {{- with .Values.env }}
        {{- toYaml . | nindent 6 }}
      {{- end }}
      image: {{ include "image" . }}
      imagePullPolicy: Always
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
          - ALL
        # readOnlyRootFilesystem: true
        runAsNonRoot: true
      resources:
        {{- if eq .Values.environment "dev"}}
        {{- if .Values.resources.dev }}
        limits:
          cpu: {{ required "Missing .Values.resources.dev.limits.cpu" .Values.resources.dev.limits.cpu }}
          memory:  {{ required "Missing .Values.resources.dev.limits.memory" .Values.resources.dev.limits.memory }}
        {{- else }}
        limits:
          cpu: {{ required "Missing .Values.resources.limits.cpu" .Values.resources.limits.cpu }}
          memory:  {{ required "Missing .Values.resources.limits.memory" .Values.resources.limits.memory }}
        {{- end }}
        requests:
          cpu: {{ include "resources.limits.cpu.max50m" .}}
          memory:  {{ include "resources.limits.memory.max100Mi" .}}
        {{- end }}

        {{- if eq .Values.environment "test"}}
        {{- if .Values.resources.test }}
        limits:
          cpu: {{ required "Missing .Values.resources.test.limits.cpu" .Values.resources.test.limits.cpu }}
          memory:  {{ required "Missing .Values.resources.test.limits.memory" .Values.resources.test.limits.memory }}
        requests:
          cpu: {{ required "Missing .Values.resources.test.requests.cpu" .Values.resources.test.requests.cpu }}
          memory: {{ required "Missing .Values.resources.test.requests.memory" .Values.resources.test.requests.memory }}
        {{- else }}
        limits:
          cpu: {{ required "Missing .Values.resources.limits.cpu" .Values.resources.limits.cpu }}
          memory:  {{ required "Missing .Values.resources.limits.memory" .Values.resources.limits.memory }}
        requests:
          cpu: {{ required "Missing .Values.resources.requests.cpu" .Values.resources.requests.cpu }}
          memory: {{ required "Missing .Values.resources.requests.memory" .Values.resources.requests.memory }}
        {{- end }}
        {{- end }}

        {{- if eq .Values.environment "kptest"}}
        {{- if .Values.resources.kptest }}
        limits:
          cpu: {{ required "Missing .Values.resources.kptest.limits.cpu" .Values.resources.kptest.limits.cpu }}
          memory:  {{ required "Missing .Values.resources.kptest.limits.memory" .Values.resources.kptest.limits.memory }}
        requests:
          cpu: {{ required "Missing .Values.resources.kptest.requests.cpu" .Values.resources.kptest.requests.cpu }}
          memory: {{ required "Missing .Values.resources.kptest.requests.memory" .Values.resources.kptest.requests.memory }}
        {{- else }}
        limits:
          cpu: {{ required "Missing .Values.resources.limits.cpu" .Values.resources.limits.cpu }}
          memory:  {{ required "Missing .Values.resources.limits.memory" .Values.resources.limits.memory }}
        requests:
          cpu: {{ required "Missing .Values.resources.requests.cpu" .Values.resources.requests.cpu }}
          memory: {{ required "Missing .Values.resources.requests.memory" .Values.resources.requests.memory }}
        {{- end }}
        {{- end }}

        {{- if eq .Values.environment "prod"}}
        {{- if .Values.resources.prod }}
        limits:
          cpu: {{ required "Missing .Values.resources.prod.limits.cpu" .Values.resources.prod.limits.cpu }}
          memory:  {{ required "Missing .Values.resources.prod.limits.memory" .Values.resources.prod.limits.memory }}
        requests:
          cpu: {{ required "Missing .Values.resources.prod.requests.cpu" .Values.resources.prod.requests.cpu }}
          memory: {{ required "Missing .Values.resources.prod.requests.memory" .Values.resources.prod.requests.memory }}
        {{- else }}
        limits:
          cpu: {{ required "Missing .Values.resources.limits.cpu" .Values.resources.limits.cpu }}
          memory:  {{ required "Missing .Values.resources.limits.memory" .Values.resources.limits.memory }}
        requests:
          cpu: {{ required "Missing .Values.resources.requests.cpu" .Values.resources.requests.cpu }}
          memory: {{ required "Missing .Values.resources.requests.memory" .Values.resources.requests.memory }}
        {{- end }}
        {{- end }}
{{- end -}}

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

{{/*
Expand the name of the chart.
*/}}
{{- define "elvia-statefulset.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "elvia-statefulset.fullname" -}}
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
{{- define "elvia-statefulset.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elvia-statefulset.labels" -}}
helm.sh/chart: {{ include "elvia-statefulset.chart" . }}
{{ include "elvia-statefulset.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elvia-statefulset.selectorLabels" -}}
app.kubernetes.io/name: {{ include "elvia-statefulset.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "elvia-statefulset.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "elvia-statefulset.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define the image, using containerregistryelvia.azurecr.io as default container registry
*/}}
{{- define "image" -}}
{{- if and .Values.image.repository (ne .Values.image.repository (printf "containerregistryelvia.azurecr.io/%s-%s" .Values.namespace .Values.name)) }} # only allow setting image repo if it is not on old deprecated syntax
{{- .Values.image.repository }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{- else }}:{{ required "Missing .Values.image.tag" .Values.image.tag }}{{- end }}
{{- else }}
{{- printf "containerregistryelvia.azurecr.io/%s/%s" .Values.namespace .Values.name }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{- else }}:{{ required "Missing .Values.image.tag" .Values.image.tag }}{{- end }}
{{- end }}
{{- end }}

{{/*
Create the host of the ingress
*/}}
{{- define "ingress.host" -}}
{{- if not .Values.ingress.subdomain }}
{{- required "Missing .Values.ingress.subdomain" ""}}
{{- end }}
{{- if eq .Values.environment "prod"}}
{{- printf "%s.elvia.io" .Values.ingress.subdomain }}
{{- else }}
{{- printf "%s.%s-elvia.io" .Values.ingress.subdomain .Values.environment }}
{{- end }}
{{- end }}

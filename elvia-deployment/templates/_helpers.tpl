{{/*
Expand the name of the chart.
*/}}
{{- define "elvia-deployment.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "elvia-deployment.fullname" -}}
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
{{- define "elvia-deployment.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "elvia-deployment.labels" -}}
helm.sh/chart: {{ include "elvia-deployment.chart" . }}
{{ include "elvia-deployment.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "elvia-deployment.selectorLabels" -}}
app.kubernetes.io/name: {{ include "elvia-deployment.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "elvia-deployment.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "elvia-deployment.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define the image, using containerregistryelvia.azurecr.io as default container registry
*/}}
{{- define "image" -}}
{{- if .Values.image.repository }}
{{- .Values.image.repository }}:{{ required "Missing .Values.image.tag" .Values.image.tag }}
{{- else }} 
{{- printf "containerregistryelvia.azurecr.io/%s-%s" .Values.namespace .Values.name }}:{{ required "Missing .Values.image.tag" .Values.image.tag }}
{{- end }}
{{- end }}

{{/*
Define the sidecar.image, using containerregistryelvia.azurecr.io as default container registry
*/}}
{{- define "sidecar.image" -}}
{{- $imagetag := .tag}}
{{- if .sidecar.image.tag}}
{{- $imagetag := .sidecar.image.tag}}
{{- end}}
{{- if .sidecar.image.repository }}
{{- .sidecar.image.repository }}:{{ required "Missing $imagetag" $imagetag }}
{{- else }} 
{{- printf "containerregistryelvia.azurecr.io/%s-%s" .namespace .sidecar.name }}:{{ required "Missing $imagetag" $imagetag }}
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

{{/*
Find the limits.cpu in millicores, but capped at 50m
*/}}
{{- define "resources.limits.cpu.max50m" -}}
{{- if .Values.resources.limits.cpu | toString | hasSuffix "m" }}
{{- .Values.resources.limits.cpu  | toString | regexFind "[0-9.]+" | min 50 -}}m
{{- else -}}
{{- mulf .Values.resources.limits.cpu 1000 | min 50 -}}m
{{- end -}}
{{- end -}}

{{/*
Find the limits.memory in Mi, but capped at 100Mi
*/}}
{{- define "resources.limits.memory.max100Mi" -}}
{{- if .Values.resources.limits.memory | toString | hasSuffix "Mi" }}
{{- .Values.resources.limits.memory  | toString | regexFind "[0-9.]+" | min 100 -}}Mi
{{- else if .Values.resources.limits.memory | toString | hasSuffix "Gi" }}
{{- .Values.resources.limits.memory  | toString | regexFind "[0-9.]+" | mulf 1000 | min 100 -}}Mi
{{- else -}}
{{- fail "value for resources.limits.memory must be given in Mi or Gi units." }}
{{- end -}}
{{- end -}}

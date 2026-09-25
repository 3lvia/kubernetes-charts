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
Shared metadata (name, namespace, labels) used by both elvia-job and elvia-cronjob.
*/}}
{{- define "elvia-job-common.metadata" -}}
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
Used both as elvia-job's .spec and as elvia-cronjob's .spec.jobTemplate.spec.
*/}}
{{- define "elvia-job-common.jobSpec" -}}
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

{{/*
Shared ConfigMap, rendered per-environment when .Values.configmap is set.
*/}}
{{- define "elvia-job-common.configmap" -}}
{{- if .Values.configmap}}

{{- if eq .Values.environment "dev"}}
{{- if .Values.configmap.dev }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
data: {{- toYaml .Values.configmap.dev | nindent 2 }} 
{{- end }}
{{- end }}

{{- if eq .Values.environment "sandbox"}}
{{- if .Values.configmap.sandbox }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
data: {{- toYaml .Values.configmap.sandbox | nindent 2 }} 
{{- end }}
{{- end }}

{{- if eq .Values.environment "test"}}
{{- if .Values.configmap.test }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
data: {{- toYaml .Values.configmap.test | nindent 2 }} 
{{- end }}
{{- end }}

{{- if eq .Values.environment "kptest"}}
{{- if .Values.configmap.kptest }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
data: {{- toYaml .Values.configmap.kptest | nindent 2 }}
{{- end }}
{{- end }}

{{- if eq .Values.environment "prod"}}
{{- if .Values.configmap.prod }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
data: {{- toYaml .Values.configmap.prod | nindent 2 }} 
{{- end }}
{{- end }}

{{- end }}
{{- end -}}

{{/*
Shared Secret, rendered per-environment when .Values.secret is set.
*/}}
{{- define "elvia-job-common.secret" -}}
{{- if .Values.secret}}

{{- if eq .Values.environment "dev"}}
{{- if .Values.secret.dev }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
type: Opaque
stringData: {{- toYaml .Values.secret.dev | nindent 2 }} 
{{- end }}
{{- end }}

{{- if eq .Values.environment "sandbox"}}
{{- if .Values.secret.sandbox }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
type: Opaque
stringData: {{- toYaml .Values.secret.sandbox | nindent 2 }} 
{{- end }}
{{- end }}

{{- if eq .Values.environment "test"}}
{{- if .Values.secret.test }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
type: Opaque
stringData: {{- toYaml .Values.secret.test | nindent 2 }} 
{{- end }}
{{- end }}

{{- if eq .Values.environment "kptest"}}
{{- if .Values.secret.kptest }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
type: Opaque
stringData: {{- toYaml .Values.secret.kptest | nindent 2 }}
{{- end }}
{{- end }}

{{- if eq .Values.environment "prod"}}
{{- if .Values.secret.prod }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
type: Opaque
stringData: {{- toYaml .Values.secret.prod | nindent 2 }} 
{{- end }}
{{- end }}

{{- end }}
{{- end -}}

{{/*
Shared NetworkPolicy, rendered when .Values.accessPolicy is set.
*/}}
{{- define "elvia-job-common.networkpolicy" -}}
{{- if .Values.accessPolicy }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ required "Missing .Values.name" .Values.name }}
  namespace: {{ required "Missing .Values.namespace" .Values.namespace }}
spec:
  podSelector:
    matchLabels:
      app: {{ required "Missing .Values.name" .Values.name }}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    {{- if .Values.accessPolicy.inbound }}
    {{- range $key, $value := .Values.accessPolicy.inbound.rules }}
    # Allow ingress traffic from user configured application
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: {{ $value.namespace }}
      {{- if $value.application }}
      podSelector:
        matchLabels:
          app: {{ $value.application }}
      {{- end }}
    {{- end }}
    {{- end }}
    {{- if .Values.ingress }}
    # Allow ingress traffic from traefik
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: dns
      podSelector:
        matchLabels:
          app.kubernetes.io/name: traefik
    {{- end }}
    # Allow ingress traffic from prometheus
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - protocol: TCP
      {{- if .Values.service }}

      {{- if .Values.service.targetPort }}
      port: {{ .Values.service.targetPort -}}
      {{- else if .Values.service.port }}
      port: {{ .Values.service.port -}}
      {{- end }}
        
      {{- else }}
      port: 2112 # Default prometheus port for worker
      {{- end }}
  egress:
  {{- if .Values.accessPolicy.outbound }}
  {{- range $key, $value := .Values.accessPolicy.outbound.rules }}
  # Allow egress traffic to user configured application
  - to: 
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: {{ $value.namespace }}
      {{- if $value.application }}
      podSelector:
        matchLabels:
          app: {{ $value.application }}
      {{- end }}
  {{- end }}
  {{- end }}
  # Allow egress traffic to the internet
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 10.0.0.0/8
        - 192.168.0.0/16
        - 172.16.0.0/12
  # Allow egress traffic to linkerd, required for service mesh
  - to: 
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: linkerd
  # Allow egress traffic to otel-collector, used for tracing
  - to: 
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
      podSelector:
        matchLabels:
          app.kubernetes.io/name: otel-collector
  # Allow dns traffic to kube-dns
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: "kube-system"
      podSelector:
        matchLabels:
          k8s-app: "kube-dns"
    ports:
    - protocol: UDP
      port: 53
{{- end }}
{{- end -}}

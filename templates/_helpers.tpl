{{/*
Expand the name of the chart.
*/}}
{{- define "rustfs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rustfs.fullname" -}}
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
{{- define "rustfs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rustfs.labels" -}}
helm.sh/chart: {{ include "rustfs.chart" . }}
{{ include "rustfs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rustfs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rustfs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rustfs.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rustfs.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "rustfs.secretName" -}}
{{- if .Values.existingSecret }}
{{- .Values.existingSecret }}
{{- else }}
{{- include "rustfs.fullname" . }}-credentials
{{- end }}
{{- end }}

{{/*
Console service name
*/}}
{{- define "rustfs.consoleServiceName" -}}
{{- printf "%s-console" (include "rustfs.fullname" .) }}
{{- end }}

{{/*
API Port
*/}}
{{- define "rustfs.apiPort" -}}
{{- .Values.config.apiPort | default 9000 }}
{{- end }}

{{/*
Console Port
*/}}
{{- define "rustfs.consolePort" -}}
{{- .Values.config.consolePort | default 9001 }}
{{- end }}

{{/*
RustFS Environment Variables
*/}}
{{- define "rustfs.environment" -}}
{{- /* Always include credentials - either from existingSecret or auto-generated secret */ -}}
- name: RUSTFS_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "rustfs.secretName" . }}
      key: RUSTFS_ACCESS_KEY
- name: RUSTFS_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "rustfs.secretName" . }}
      key: RUSTFS_SECRET_KEY
{{- if .Values.env }}
{{- toYaml .Values.env }}
{{- end }}
{{- end }}

{{/*
Cluster domain for services
*/}}
{{- define "rustfs.clusterDomain" -}}
{{- .Values.clusterDomain | default "cluster.local" }}
{{- end }}

{{/*
Common pod labels
*/}}
{{- define "rustfs.podLabels" -}}
{{- include "rustfs.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- if .Values.podLabels }}
{{- toYaml .Values.podLabels }}
{{- end }}
{{- end }}

{{/*
ConfigMap name
*/}}
{{- define "rustfs.configMapName" -}}
{{- printf "%s-config" (include "rustfs.fullname" .) }}
{{- end }}

{{/*
Generate RUSTFS volumes configuration
For single-node (replicas=1): Always returns "/data/rustfs0" (local path)
For multi-node (replicas>1): Returns distributed URL pattern with {expansion} syntax

Logic:
1. Single-node: Use local path "/data/rustfs0" regardless of driverPerNode
   (Only first drive is used due to erasure coding constraints in single-node)
2. Multi-node + single drive: "http://service-{0...N}.service:port/data/rustfs0"
3. Multi-node + multiple drives: "http://service-{0...N}.service:port/data/rustfs{0...M}"

Examples:
- replicas=1, driverPerNode=3 → "/data/rustfs0" (single-node, only first drive used)
- replicas=3, driverPerNode=1 → "http://rustfs-{0...2}.rustfs:9000/data/rustfs0"
- replicas=3, driverPerNode=2 → "http://rustfs-{0...2}.rustfs:9000/data/rustfs{0...1}"
*/}}
{{- define "rustfs.volumesPattern" -}}
{{- $replicas := .Values.replicas -}}
{{- $driverPerNode := .Values.driverPerNode -}}
{{- $apiPort := include "rustfs.apiPort" . -}}
{{- $fullname := include "rustfs.fullname" . -}}
{{- $mountPath := .Values.mountPath | default "/data" -}}

{{- /* Single-node: Always use local path, only first drive */ -}}
{{- if eq ($replicas | int) 1 -}}
{{ $mountPath }}/rustfs0
{{- else -}}
{{- /* Multi-node: Use distributed URL pattern */ -}}
{{- if eq ($driverPerNode | int) 1 -}}
{{- /* Multi-node, single drive per node */ -}}
http://{{ $fullname }}-{0...{{ sub ($replicas | int) 1 }}}.{{ $fullname }}:{{ $apiPort }}{{ $mountPath }}/rustfs0
{{- else -}}
{{- /* Multi-node, multiple drives per node */ -}}
http://{{ $fullname }}-{0...{{ sub ($replicas | int) 1 }}}.{{ $fullname }}:{{ $apiPort }}{{ $mountPath }}/rustfs{0...{{ sub ($driverPerNode | int) 1 }}}
{{- end -}}
{{- end -}}
{{- end }}

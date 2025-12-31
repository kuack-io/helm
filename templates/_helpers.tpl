{{/*
Expand the name of the chart.
*/}}
{{- define "kuack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kuack.fullname" -}}
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
{{- define "kuack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kuack.labels" -}}
helm.sh/chart: {{ include "kuack.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Node component helpers
*/}}
{{- define "kuack-node.name" -}}
{{- "kuack-node" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kuack-node.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- "kuack-node" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "kuack-node.labels" -}}
{{ include "kuack.labels" . }}
{{ include "kuack-node.selectorLabels" . }}
{{- end }}

{{- define "kuack-node.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kuack-node.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: node
{{- end }}

{{- define "kuack-node.serviceAccountName" -}}
{{- if .Values.node.serviceAccount.create }}
{{- default (include "kuack-node.fullname" .) .Values.node.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.node.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Agent component helpers
*/}}
{{- define "kuack-agent.name" -}}
{{- "kuack-agent" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kuack-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- "kuack-agent" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "kuack-agent.labels" -}}
{{ include "kuack.labels" . }}
{{ include "kuack-agent.selectorLabels" . }}
{{- end }}

{{- define "kuack-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kuack-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: agent
{{- end }}

{{- define "kuack-agent.serviceAccountName" -}}
{{- if .Values.agent.serviceAccount.create }}
{{- default (include "kuack-agent.fullname" .) .Values.agent.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.agent.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Construct the image reference for node component.
Handles: repository, repository:tag, digest override
Properly handles registry:port/repository:tag format
*/}}
{{- define "kuack-node.image" -}}
{{- if .Values.node.image.digest -}}
  {{- $repo := .Values.node.image.repository -}}
  {{- if regexMatch ".*/.+:.+$" $repo -}}
    {{- $repo = regexReplaceAll "(.*/.+):.+$" $repo "$1" -}}
  {{- end -}}
  {{- printf "%s@%s" $repo .Values.node.image.digest -}}
{{- else -}}
  {{- $explicitTag := .Values.node.image.tag | default "" -}}
  {{- $repo := .Values.node.image.repository -}}
  {{- if ne $explicitTag "" -}}
    {{- if regexMatch ".*/.+:.+$" $repo -}}
      {{- $repo = regexReplaceAll "(.*/.+):.+$" $repo "$1" -}}
    {{- end -}}
    {{- printf "%s:%s" $repo $explicitTag -}}
  {{- else if regexMatch ".*/.+:.+$" $repo -}}
    {{- $repo -}}
  {{- else -}}
    {{- printf "%s:%s" $repo "latest" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Construct the image reference for agent component.
Handles: repository, repository:tag, digest override
Properly handles registry:port/repository:tag format
*/}}
{{- define "kuack-agent.image" -}}
{{- if .Values.agent.image.digest -}}
  {{- $repo := .Values.agent.image.repository -}}
  {{- if regexMatch ".*/.+:.+$" $repo -}}
    {{- $repo = regexReplaceAll "(.*/.+):.+$" $repo "$1" -}}
  {{- end -}}
  {{- printf "%s@%s" $repo .Values.agent.image.digest -}}
{{- else -}}
  {{- $explicitTag := .Values.agent.image.tag | default "" -}}
  {{- $repo := .Values.agent.image.repository -}}
  {{- if ne $explicitTag "" -}}
    {{- if regexMatch ".*/.+:.+$" $repo -}}
      {{- $repo = regexReplaceAll "(.*/.+):.+$" $repo "$1" -}}
    {{- end -}}
    {{- printf "%s:%s" $repo $explicitTag -}}
  {{- else if regexMatch ".*/.+:.+$" $repo -}}
    {{- $repo -}}
  {{- else -}}
    {{- printf "%s:%s" $repo "latest" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
ConfigMap data content for node component.
Used for checksum calculation in deployment.
*/}}
{{- define "kuack-node.configMapData" -}}
NODE_NAME: {{ .Values.node.config.name | quote }}
PUBLIC_PORT: {{ .Values.node.http.publicPort | quote }}
INTERNAL_PORT: {{ .Values.node.http.internalPort | quote }}
DISABLE_TAINT: {{ .Values.node.config.disableTaint | quote }}
{{- if .Values.node.kubeconfig.path }}
KUBECONFIG: {{ .Values.node.kubeconfig.path | quote }}
{{- end }}
KLOG_VERBOSITY: {{ .Values.node.logging.verbosity | quote }}
{{- end -}}

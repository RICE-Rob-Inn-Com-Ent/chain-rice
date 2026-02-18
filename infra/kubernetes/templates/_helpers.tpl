{{/*
Expand the name of the chart.
*/}}
{{- define "rice-mono.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "rice-mono.fullname" -}}
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
{{- define "rice-mono.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rice-mono.labels" -}}
helm.sh/chart: {{ include "rice-mono.chart" . }}
{{ include "rice-mono.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rice-mono.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rice-mono.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "rice-mono.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "rice-mono.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for HPA
*/}}
{{- define "rice-mono.hpa.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "autoscaling/v2" }}
{{- print "autoscaling/v2" }}
{{- else }}
{{- print "autoscaling/v2beta2" }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for Ingress
*/}}
{{- define "rice-mono.ingress.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1" }}
{{- print "networking.k8s.io/v1" }}
{{- else if .Capabilities.APIVersions.Has "networking.k8s.io/v1beta1" }}
{{- print "networking.k8s.io/v1beta1" }}
{{- else }}
{{- print "extensions/v1beta1" }}
{{- end }}
{{- end }}

{{/*
Generate backend image with tag
*/}}
{{- define "rice-mono.backend.image" -}}
{{- printf "%s:%s" .Values.backend.image.repository (.Values.backend.image.tag | default "latest") }}
{{- end }}

{{/*
Generate frontend image with tag
*/}}
{{- define "rice-mono.frontend.image" -}}
{{- printf "%s:%s" .Values.frontend.image.repository (.Values.frontend.image.tag | default "latest") }}
{{- end }}

{{/*
Validate required values
*/}}
{{- define "rice-mono.validateValues" -}}
{{- if not .Values.global.domain }}
  {{- fail "global.domain is required" }}
{{- end }}
{{- if and .Values.database.enabled (not .Values.database.external) }}
  {{- if not .Values.database.internal }}
    {{- fail "database.internal configuration is required when database.external is false" }}
  {{- end }}
{{- end }}
{{- end }}

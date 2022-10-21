{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "execution-helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "execution-helm.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{* {{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.credentials.userNexusUrl (printf "%s:%s" .Values.credentials.userNexusUsername .Values.credentials.userNexusPassword | b64enc) | b64enc }}
{{- end }} *}

{* {{- define "sfb-imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.credentials.sfbNexus.registry (printf "%s:%s" .Values.credentials.sfbNexus.username .Values.credentials.sfbNexusPassword | b64enc) | b64enc }}
{{- end }} *}

{* {{- define "docker-registry" }}
{{- printf "%s/%s/" .Values.credentials.userNexusUrl .Values.credentials.dockerRepositoryName | b64enc }}
{{- end }} *}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "execution-helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

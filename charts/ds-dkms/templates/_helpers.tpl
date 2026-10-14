{{/*
Common helpers for ds-dkms.
*/}}

{{/* ─── Naming ──────────────────────────────────────────────────────── */}}

{{- define "ds-dkms.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ds-dkms.fullname" -}}
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

{{- define "ds-dkms.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ds-dkms.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "ds-dkms.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* ─── Common labels ───────────────────────────────────────────────── */}}

{{- define "ds-dkms.labels" -}}
helm.sh/chart: {{ include "ds-dkms.chart" . }}
app.kubernetes.io/name: {{ include "ds-dkms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "ds-dkms.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ds-dkms.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* ─── Component labels ────────────────────────────────────────────── */}}

{{- define "ds-dkms.witness.labels" -}}
{{ include "ds-dkms.labels" . }}
app.kubernetes.io/component: witness
{{- end -}}

{{- define "ds-dkms.witness.selectorLabels" -}}
{{ include "ds-dkms.selectorLabels" . }}
app.kubernetes.io/component: witness
{{- end -}}

{{- define "ds-dkms.watcher.labels" -}}
{{ include "ds-dkms.labels" . }}
app.kubernetes.io/component: watcher
{{- end -}}

{{- define "ds-dkms.watcher.selectorLabels" -}}
{{ include "ds-dkms.selectorLabels" . }}
app.kubernetes.io/component: watcher
{{- end -}}

{{- define "ds-dkms.mesagkesto.labels" -}}
{{ include "ds-dkms.labels" . }}
app.kubernetes.io/component: mesagkesto
{{- end -}}

{{- define "ds-dkms.mesagkesto.selectorLabels" -}}
{{ include "ds-dkms.selectorLabels" . }}
app.kubernetes.io/component: mesagkesto
{{- end -}}

{{/* ─── URL templating ──────────────────────────────────────────────── */}}

{{/*
Default witness public URL pattern. {idx} is replaced per-replica by the
rendering code.
*/}}
{{- define "ds-dkms.witness.publicUrlPattern" -}}
{{- if .Values.witness.publicUrlPattern -}}
{{- .Values.witness.publicUrlPattern -}}
{{- else -}}
https://dkms-witness-{idx}.{{ required "baseDomain is required when witness.publicUrlPattern is unset" .Values.baseDomain }}
{{- end -}}
{{- end -}}

{{- define "ds-dkms.watcher.publicUrl" -}}
{{- if .Values.watcher.publicUrl -}}
{{- .Values.watcher.publicUrl -}}
{{- else -}}
https://dkms-watcher.{{ required "baseDomain is required when watcher.publicUrl is unset" .Values.baseDomain }}
{{- end -}}
{{- end -}}

{{- define "ds-dkms.mesagkesto.publicUrl" -}}
{{- if .Values.mesagkesto.publicUrl -}}
{{- .Values.mesagkesto.publicUrl -}}
{{- else -}}
https://dkms-mesagkesto.{{ required "baseDomain is required when mesagkesto.publicUrl is unset" .Values.baseDomain }}
{{- end -}}
{{- end -}}

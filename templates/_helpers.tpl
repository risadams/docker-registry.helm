{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "docker-registry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "docker-registry.fullname" -}}
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

{{/*
Common selector labels. These are immutable on Deployments/StatefulSets, so they
must remain stable across releases (app + release only).
*/}}
{{- define "docker-registry.match-labels" -}}
app: {{ template "docker-registry.name" . }}
release: {{ .Release.Name }}
{{- end -}}

{{/*
Common labels. Combines the stable selector labels with chart metadata and the
labels recommended by Kubernetes and Helm best practices.
*/}}
{{- define "docker-registry.labels" -}}
{{ include "docker-registry.match-labels" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
heritage: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ template "docker-registry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}

{{/*
Common labels merged with a caller-supplied label map, with the caller's labels
taking precedence. Use this anywhere user-provided labels (e.g.
.Values.service.labels) are combined with the chart labels, so an overridden key
such as "release" collapses to a single map entry instead of emitting a
duplicate YAML key.

Usage: {{ include "docker-registry.labels.merged" (dict "ctx" . "extra" .Values.service.labels) | nindent 4 }}
*/}}
{{- define "docker-registry.labels.merged" -}}
{{- $base := fromYaml (include "docker-registry.labels" .ctx) -}}
{{- $extra := .extra | default dict -}}
{{- toYaml (merge (deepCopy $extra) $base) -}}
{{- end -}}

{{/*
Resolve the name of the Secret to use. When existingSecret is set, the chart
references that Secret instead of creating its own.
*/}}
{{- define "docker-registry.secretName" -}}
{{- if .Values.existingSecret -}}
{{- .Values.existingSecret -}}
{{- else -}}
{{- template "docker-registry.fullname" . }}-secret
{{- end -}}
{{- end -}}

{{/*
Create a livenessProbe.
Allow the default value to be completely overridden by an optional value,
while retaining the original livenessProbe logic.
*/}}
{{- define "docker-registry.livenessProbe" -}}
livenessProbe:
{{- if .Values.livenessProbe }}
{{ .Values.livenessProbe | toYaml | indent 2 }}
{{- else }}
  httpGet:
{{- if (include "docker-registry.tlsSecretName" .) }}
    scheme: HTTPS
{{- end }}
    path: /
    port: 5000
{{- end -}}
{{- end -}}

{{/*
Create a readinessProbe.
Allow the default value to be completely overridden by an optional value,
while retaining the original readinessProbe logic.
*/}}
{{- define "docker-registry.readinessProbe" -}}
readinessProbe:
{{- if .Values.readinessProbe }}
{{ .Values.readinessProbe | toYaml | indent 2 }}
{{- else }}
  httpGet:
{{- if (include "docker-registry.tlsSecretName" .) }}
    scheme: HTTPS
{{- end }}
    path: /
    port: 5000
{{- end -}}
{{- end -}}

{{/*
Resolve the TLS Secret name to serve HTTPS, or empty string when TLS is off.
Precedence: an explicit existing Secret (`tlsSecretName`) wins; otherwise, when
both `tls.crt` and `tls.key` are provided the chart creates `<fullname>-tls`
(see tls-secret.yaml) and uses that. Returning a string means this helper also
works as the "is TLS enabled?" check in an `if`.
*/}}
{{- define "docker-registry.tlsSecretName" -}}
{{- if .Values.tlsSecretName -}}
{{- .Values.tlsSecretName -}}
{{- else if and .Values.tls .Values.tls.crt .Values.tls.key -}}
{{- printf "%s-tls" (include "docker-registry.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "docker-registry.envs" -}}
- name: REGISTRY_HTTP_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.secretName" . }}
      key: haSharedSecret

{{- if .Values.secrets.htpasswd }}
- name: REGISTRY_AUTH
  value: "htpasswd"
- name: REGISTRY_AUTH_HTPASSWD_REALM
  value: "Registry Realm"
- name: REGISTRY_AUTH_HTPASSWD_PATH
  value: "/auth/htpasswd"
{{- end }}

{{- if (include "docker-registry.tlsSecretName" .) }}
- name: REGISTRY_HTTP_TLS_CERTIFICATE
  value: /etc/ssl/docker/tls.crt
- name: REGISTRY_HTTP_TLS_KEY
  value: /etc/ssl/docker/tls.key
{{- end -}}

{{- if eq .Values.storage "filesystem" }}
- name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
  value: "/var/lib/registry"
{{- else if eq .Values.storage "azure" }}
- name: REGISTRY_STORAGE_AZURE_ACCOUNTNAME
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.secretName" . }}
      key: azureAccountName
- name: REGISTRY_STORAGE_AZURE_ACCOUNTKEY
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.secretName" . }}
      key: azureAccountKey
- name: REGISTRY_STORAGE_AZURE_CONTAINER
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.secretName" . }}
      key: azureContainer
{{- else if eq .Values.storage "s3" }}
- name: REGISTRY_STORAGE_S3_REGION
  value: {{ required ".Values.s3.region is required" .Values.s3.region }}
- name: REGISTRY_STORAGE_S3_BUCKET
  value: {{ required ".Values.s3.bucket is required" .Values.s3.bucket }}
{{- /*
  Only wire S3 credential env vars when credentials are actually configured.
  Guard .Values.secrets.s3 itself first: when relying on an EC2/IRSA instance
  profile, secrets.s3 is unset and dereferencing its keys would be a nil pointer.
*/}}
{{- $s3secrets := .Values.secrets.s3 | default dict }}
{{- if or (and $s3secrets.secretKey $s3secrets.accessKey) $s3secrets.secretRef }}
- name: REGISTRY_STORAGE_S3_ACCESSKEY
  valueFrom:
    secretKeyRef:
      name: {{ if $s3secrets.secretRef }}{{ $s3secrets.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      key: s3AccessKey
- name: REGISTRY_STORAGE_S3_SECRETKEY
  valueFrom:
    secretKeyRef:
      name: {{ if $s3secrets.secretRef }}{{ $s3secrets.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      key: s3SecretKey
{{- end -}}

{{- if .Values.s3.regionEndpoint }}
- name: REGISTRY_STORAGE_S3_REGIONENDPOINT
  value: {{ .Values.s3.regionEndpoint }}
{{- end -}}

{{- if .Values.s3.rootdirectory }}
- name: REGISTRY_STORAGE_S3_ROOTDIRECTORY
  value: {{ .Values.s3.rootdirectory | quote }}
{{- end -}}

{{- if .Values.s3.encrypt }}
- name: REGISTRY_STORAGE_S3_ENCRYPT
  value: {{ .Values.s3.encrypt | quote }}
{{- end -}}

{{- if .Values.s3.secure }}
- name: REGISTRY_STORAGE_S3_SECURE
  value: {{ .Values.s3.secure | quote }}
{{- end -}}

{{- if .Values.s3.forcepathstyle }}
- name: REGISTRY_STORAGE_S3_FORCEPATHSTYLE
  value: {{ .Values.s3.forcepathstyle | quote }}
{{- end -}}

{{- if .Values.s3.skipverify }}
- name: REGISTRY_STORAGE_S3_SKIPVERIFY
  value: {{ .Values.s3.skipverify | quote }}
{{- end -}}

{{- else if eq .Values.storage "swift" }}
- name: REGISTRY_STORAGE_SWIFT_AUTHURL
  value: {{ required ".Values.swift.authurl is required" .Values.swift.authurl }}
- name: REGISTRY_STORAGE_SWIFT_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.secretName" . }}
      key: swiftUsername
- name: REGISTRY_STORAGE_SWIFT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.secretName" . }}
      key: swiftPassword
- name: REGISTRY_STORAGE_SWIFT_CONTAINER
  value: {{ required ".Values.swift.container is required" .Values.swift.container }}
{{- end -}}

{{- if .Values.proxy.enabled }}
- name: REGISTRY_PROXY_REMOTEURL
  value: {{ required ".Values.proxy.remoteurl is required" .Values.proxy.remoteurl }}
- name: REGISTRY_PROXY_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.proxy.secretRef }}{{ .Values.proxy.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      key: proxyUsername
- name: REGISTRY_PROXY_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.proxy.secretRef }}{{ .Values.proxy.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      key: proxyPassword
{{- end -}}

{{- if .Values.persistence.deleteEnabled }}
- name: REGISTRY_STORAGE_DELETE_ENABLED
  value: "true"
{{- end -}}

{{- /*
  Redis blob descriptor cache. The non-secret redis connection settings come
  from `configData.redis` (rendered into config.yml); the password is injected
  from a Secret here so it never lands in the ConfigMap.
*/}}
{{- if .Values.redis.password }}
- name: REGISTRY_REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.redis.secretRef }}{{ .Values.redis.secretRef }}{{ else }}{{ template "docker-registry.secretName" . }}{{ end }}
      key: redisPassword
{{- end -}}

{{- with .Values.extraEnvVars }}
{{ toYaml . }}
{{- end -}}

{{- end -}}

{{- define "docker-registry.volumeMounts" -}}
- name: "{{ template "docker-registry.fullname" . }}-config"
  mountPath: {{ .Values.configPath }}

{{- if .Values.secrets.htpasswd }}
- name: auth
  mountPath: /auth
  readOnly: true
{{- end }}

{{- if eq .Values.storage "filesystem" }}
- name: data
  mountPath: /var/lib/registry/
{{- end }}

{{- if (include "docker-registry.tlsSecretName" .) }}
- mountPath: /etc/ssl/docker
  name: tls-cert
  readOnly: true
{{- end }}

{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}

{{- end -}}

{{- define "docker-registry.volumes" -}}
- name: {{ template "docker-registry.fullname" . }}-config
  configMap:
    name: {{ template "docker-registry.fullname" . }}-config

{{- if .Values.secrets.htpasswd }}
- name: auth
  secret:
    secretName: {{ template "docker-registry.secretName" . }}
    items:
    - key: htpasswd
      path: htpasswd
{{- end }}

{{- if (and (eq .Values.storage "filesystem") (not .Values.useStatefulSet)) }}
- name: data
  {{- if .Values.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ if .Values.persistence.existingClaim }}{{ .Values.persistence.existingClaim }}{{- else }}{{ template "docker-registry.fullname" . }}{{- end }}
  {{- else }}
  emptyDir:
    sizeLimit: {{ .Values.emptydir.size }}
  {{- end -}}
{{- end }}

{{- if (include "docker-registry.tlsSecretName" .) }}
- name: tls-cert
  secret:
    secretName: {{ include "docker-registry.tlsSecretName" . }}
{{- end }}

{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}

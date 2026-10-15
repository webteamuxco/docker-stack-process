# Trivy Security Report

{{ range . }}
## {{ .Target }}

**Type:** {{ .Type }}

{{ if .Vulnerabilities }}
### Vulnerabilities

| Package | ID | Severity | Installed Version | Fixed Version |
| --- | --- | --- | --- | --- |
{{ range .Vulnerabilities }}
| {{ .PkgName }} | {{ .VulnerabilityID }} | {{ .Severity }} | {{ .InstalledVersion }} | {{ .FixedVersion }} |
{{ end }}
{{ else }}
No vulnerabilities found.
{{ end }}

{{ if .Misconfigurations }}
### Misconfigurations

| ID | Severity | Title | Message |
| --- | --- | --- | --- |
{{ range .Misconfigurations }}
| {{ .ID }} | {{ .Severity }} | {{ .Title }} | {{ .Message }} |
{{ end }}
{{ else }}
No misconfigurations found.
{{ end }}

---
{{ end }}
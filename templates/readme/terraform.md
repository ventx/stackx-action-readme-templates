## Terraform

{{ .Terraform }}

### Features

{{ range .Features }}
* {{ . }}
{{- end }}

### Resources

{{ range .Resources }}
* {{ . }}
{{- end }}


<!-- BEGIN_TF_DOCS -->
{{ .Content }}
<!-- END_TF_DOCS -->


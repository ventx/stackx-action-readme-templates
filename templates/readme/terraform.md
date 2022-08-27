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

### Opinions

Our Terraform modules are are highly opionated:

* Keep modules small, focused, simple and easy to understand
* Prefer simple code over complex code
* Prefer [KISS](https://en.wikipedia.org/wiki/KISS_principle) > [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
* Set some sane default values for variables, but do not set a default value if user input is strictly required


These opinions can be seen as some _"soft"_ rules but which are not strictly required.

<!-- BEGIN_TF_DOCS -->
{{ .Content }}
<!-- END_TF_DOCS -->


package main

import (
	"bytes"
	"flag"
	"fmt"
	"gopkg.in/yaml.v3"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"text/template"
)

type Acknowledgements struct {
	Acknowledgements string
}

type About struct {
	About      interface{}
	ImageDesc1 interface{}
	ImageDesc2 interface{}
	ImageFile1 interface{}
	ImageFile2 interface{}
	RepoSlug   string
}

type BuiltWith struct {
	BuiltWith interface{}
}

type DocsCodeOfConduct struct {
	RepoSlug string
}

type DocsContributing struct {
	RepoName string
	RepoSlug string
}

type DocsSecurity struct {
	RepoName string
	RepoSlug string
}

type Contributing struct {
	Contributing string
	RepoSlug     string
}

type Footer struct {
	Acknowledgements *bytes.Buffer
	Footer           string
	License          *bytes.Buffer
	Security         *bytes.Buffer
	Ventx            *bytes.Buffer
	Contributing     *bytes.Buffer
	Support          *bytes.Buffer
	Roadmap          *bytes.Buffer
}

type GettingStarted struct {
	GettingStarted string
	Quickstart     interface{}
	RepoSlug       string
	Prerequisites  interface{}
}

type Header struct {
	About          *bytes.Buffer
	BuiltWith      *bytes.Buffer
	GettingStarted *bytes.Buffer
	Header         string
	RepoSlug       string
	Usage          *bytes.Buffer
}

type Helm struct {
	Helm string
}

type License struct {
	License string
}

type Readme struct {
	Header    *bytes.Buffer
	Footer    *bytes.Buffer
	Helm      *bytes.Buffer
	Terraform *bytes.Buffer
}

type Roadmap struct {
	Roadmap  string
	RepoSlug string
}

type Security struct {
	Security string
	RepoName string
}

type Support struct {
	Support  string
	RepoSlug string
}

type Terraform struct {
	Content     string
	Terraform   interface{}
	Description interface{}
	Resources   interface{}
	Features    interface{}
}

type Usage struct {
	Usage interface{}
}

type Ventx struct {
	Ventx    string
	RepoName string
	RepoSlug string
}

// Declare type pointer to a template
var about *template.Template
var acknowledgements *template.Template
var builtwith *template.Template
var contributing *template.Template
var docsContributing *template.Template
var docsCodeOfConduct *template.Template
var docsSecurity *template.Template
var footer *template.Template
var gettingStarted *template.Template
var header *template.Template
var helm *template.Template
var license *template.Template
var readme *template.Template
var roadmap *template.Template
var security *template.Template
var support *template.Template
var terraform *template.Template
var usage *template.Template
var ventx *template.Template

const readmeTmplPath = "./docs/README.md.tmpl"
const readmeConfPath = "./docs/README.yaml"
const readmeFilePath = "README.md"
const docsCocPath = "./.github/CODE_OF_CONDUCT.md"
const docsContributingPath = "./.github/CONTRIBUTING.md"
const docsSecurityPath = "./.github/SECURITY.md"

// Using the init function to make sure the template is only parsed once in the program
func init() {
	about = template.Must(template.ParseFiles("/readme/about.md"))
	acknowledgements = template.Must(template.ParseFiles("/readme/acknowledgements.md"))
	builtwith = template.Must(template.ParseFiles("/readme/builtwith.md"))
	contributing = template.Must(template.ParseFiles("/readme/contributing.md"))
	docsContributing = template.Must(template.ParseFiles("/docs/CONTRIBUTING.md"))
	docsCodeOfConduct = template.Must(template.ParseFiles("/docs/CODE_OF_CONDUCT.md"))
	docsSecurity = template.Must(template.ParseFiles("/docs/SECURITY.md"))
	footer = template.Must(template.ParseFiles("/readme/footer.md"))
	gettingStarted = template.Must(template.ParseFiles("/readme/gettingstarted.md"))
	header = template.Must(template.ParseFiles("/readme/header.md"))
	helm = template.Must(template.ParseFiles("/readme/helm.md"))
	license = template.Must(template.ParseFiles("/readme/license.md"))
	readme = template.Must(template.ParseFiles(readmeTmplPath))
	roadmap = template.Must(template.ParseFiles("/readme/roadmap.md"))
	security = template.Must(template.ParseFiles("/readme/security.md"))
	support = template.Must(template.ParseFiles("/readme/support.md"))
	terraform = template.Must(template.ParseFiles("/readme/terraform.md"))
	usage = template.Must(template.ParseFiles("/readme/usage.md"))
	ventx = template.Must(template.ParseFiles("/readme/ventx.md"))
}

func main() {
	var readmeTemplate Readme

	// Command line flags
	helmFlag := flag.Bool("helm", false, "Generate Helm README template")
	terraformFlag := flag.Bool("terraform", false, "Generate Terraform README template")
	flag.Parse()

	// Load YAML config file
	log.Printf("Loading config file: %s", readmeConfPath)
	yamlFile, err := ioutil.ReadFile(readmeConfPath)
	if err != nil {
		log.Fatal(err)
	}

	data := make(map[interface{}]interface{})
	err2 := yaml.Unmarshal(yamlFile, &data)
	if err2 != nil {
		log.Fatal(err2)
	}

	var aboutDesc interface{}
	var builtwithDesc interface{}
	var features interface{}
	var imageDesc1 interface{}
	var imageDesc2 interface{}
	var imageFile1 interface{}
	var ImageFile2 interface{}
	var prerequisites interface{}
	var quickstart interface{}
	var resources interface{}
	var terraformDesc interface{}
	var usageDesc interface{}
	log.Println("Get keys from YAML in: readme.yaml")
	for k, v := range data {
		//fmt.Printf("%s -> %d\n", k, v)

		if k == "about" {
			aboutDesc = v
		}

		if k == "builwith" {
			builtwithDesc = v
		}

		if k == "features" {
			features = v
		}

		if k == "imageDesc1" {
			imageDesc1 = v
		}

		if k == "imageDesc2" {
			imageDesc2 = v
		}

		if k == "imageFile1" {
			imageFile1 = v
		}

		if k == "imageFile2" {
			ImageFile2 = v
		}

		if k == "resources" {
			resources = v
		}

		if k == "terraform" {
			terraformDesc = v
		}

		if k == "prerequisites" {
			prerequisites = v
		}

		if k == "quickstart" {
			quickstart = v
		}

		if k == "usage" {
			usageDesc = v
		}
	}

	// Git repo slug, e.g.: "ventx/stackx-terraform-aws-network"
	ghSlug, ok := os.LookupEnv("GITHUB_REPOSITORY")
	if !ok {
		log.Fatalf("\nEnvironment variable %s not set", "GITHUB_REPOSITORY")
	} else {
		fmt.Printf("%s=%s\n", "GITHUB_REPOSITORY", ghSlug)
	}

	// Git repo name, e.g.: "stackx-terraform-aws-network"
	ghRepoSlice := strings.Split(ghSlug, "/")
	ghRepo := ghRepoSlice[1]

	// Git repo owner, e.g.: "ventx"
	//ghOwner := ghRepoSlice[1]
	//fmt.Printf("\nghOwner: %s\n", ghOwner)

	// HEADER
	log.Printf("--> Building template: %s", about.ParseName)
	var aboutBuffer bytes.Buffer
	aboutTemplate := About{
		About:      aboutDesc,
		ImageDesc1: imageDesc1,
		ImageDesc2: imageDesc2,
		ImageFile1: imageFile1,
		ImageFile2: ImageFile2,
		RepoSlug:   ghSlug,
	}
	err = about.Execute(&aboutBuffer, aboutTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// HEADER >> About
	log.Printf("--> Building template: %s", about.ParseName)
	var builtwithBuffer bytes.Buffer
	builtwithTemplate := BuiltWith{
		BuiltWith: builtwithDesc,
	}
	err = builtwith.Execute(&builtwithBuffer, builtwithTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// HEADER >> Getting Started
	log.Printf("--> Building template: %s", gettingStarted.ParseName)
	var gettingStartedhBuffer bytes.Buffer
	gettingStartedTemplate := GettingStarted{
		GettingStarted: "gettingstartedhblah",
		Prerequisites:  prerequisites,
		Quickstart:     quickstart,
	}
	err = gettingStarted.Execute(&gettingStartedhBuffer, gettingStartedTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// HEADER >> Usage
	log.Printf("--> Building template: %s", usage.ParseName)
	var usageBuffer bytes.Buffer
	usageTemplate := Usage{
		Usage: usageDesc,
	}
	err = usage.Execute(&usageBuffer, usageTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// HEADER
	log.Printf("--> Building template: %s", header.ParseName)
	var headerBuffer bytes.Buffer
	headerTemplate := Header{
		Header:         "headerblah",
		About:          &aboutBuffer,
		BuiltWith:      &builtwithBuffer,
		GettingStarted: &gettingStartedhBuffer,
		Usage:          &usageBuffer,
		RepoSlug:       ghSlug,
	}
	err = header.Execute(&headerBuffer, headerTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// FOOTER >> Contributing
	log.Printf("--> Building template: %s", contributing.ParseName)
	var contributingBuffer bytes.Buffer
	contributingTemplate := Contributing{
		Contributing: "contribblah",
		RepoSlug:     ghSlug,
	}
	err = contributing.Execute(&contributingBuffer, contributingTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// FOOTER >> Acknoledgements
	log.Printf("--> Building template: %s", acknowledgements.ParseName)
	var acknowledgementsBuffer bytes.Buffer
	acknowledgementsTemplate := Acknowledgements{
		Acknowledgements: "ackblah",
	}
	err = acknowledgements.Execute(&acknowledgementsBuffer, acknowledgementsTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// FOOTER >> License
	log.Printf("--> Building template: %s", license.ParseName)
	var licenseBuffer bytes.Buffer
	licenseTemplate := License{License: "licenseblah"}
	err = license.Execute(&licenseBuffer, licenseTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// FOOTER >> Roadmap
	log.Printf("--> Building template: %s", roadmap.ParseName)
	var roadmapBuffer bytes.Buffer
	roadmapTemplate := Roadmap{
		Roadmap:  "roadmapblah",
		RepoSlug: ghSlug,
	}
	err = roadmap.Execute(&roadmapBuffer, roadmapTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// FOOTER >> Security
	log.Printf("--> Building template: %s", security.ParseName)
	var securityBuffer bytes.Buffer
	securityTemplate := Security{
		Security: "securityblah",
		RepoName: ghRepo,
	}
	err = security.Execute(&securityBuffer, securityTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// FOOTER >> Support
	log.Printf("--> Building template: %s", support.ParseName)
	var supportBuffer bytes.Buffer
	supportTemplate := Support{
		Support:  "supportblah",
		RepoSlug: ghSlug,
	}
	err = support.Execute(&supportBuffer, supportTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// FOOTER >> ventx
	log.Printf("--> Building template: %s", ventx.ParseName)
	var ventxBuffer bytes.Buffer
	ventxTemplate := Ventx{
		Ventx:    "securityblah",
		RepoName: ghRepo,
		RepoSlug: ghSlug,
	}
	err = ventx.Execute(&ventxBuffer, ventxTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// FOOTER
	log.Printf("--> Building template: %s", footer.ParseName)
	// Finally build the footer from above templates
	var footerBuffer bytes.Buffer
	footerTemplate := Footer{
		Acknowledgements: &acknowledgementsBuffer,
		Contributing:     &contributingBuffer,
		License:          &licenseBuffer,
		Roadmap:          &roadmapBuffer,
		Security:         &securityBuffer,
		Support:          &supportBuffer,
		Ventx:            &ventxBuffer,
	}
	err = footer.Execute(&footerBuffer, footerTemplate)
	if err != nil {
		log.Fatalln(err)
	}

	// Optionally, controlled by command line args
	if *helmFlag {
		// HELM
		log.Printf("--> Building template: %s", helm.ParseName)
		var helmBuffer bytes.Buffer
		helmTemplate := Helm{Helm: "helmblah"}
		err := helm.Execute(&helmBuffer, helmTemplate)
		if err != nil {
			log.Fatalln(err)
		}
		readmeTemplate = Readme{Header: &headerBuffer, Footer: &footerBuffer, Helm: &helmBuffer}
	} else if *terraformFlag {
		// TERRAFORM
		log.Printf("--> Building template: %s", terraform.ParseName)
		var terraformBuffer bytes.Buffer
		terraformTemplate := Terraform{
			Content:   "{{ .Content }}",
			Terraform: terraformDesc,
			Resources: resources,
			Features:  features,
		}
		err := terraform.Execute(&terraformBuffer, terraformTemplate)
		if err != nil {
			log.Fatalln(err)
		}
		readmeTemplate = Readme{Header: &headerBuffer, Footer: &footerBuffer, Terraform: &terraformBuffer}
	} else {
		readmeTemplate = Readme{Header: &headerBuffer, Footer: &footerBuffer}
	}

	// FINAL README generation and save to file
	readmeFile, err := os.Create(readmeFilePath)
	if err != nil {
		log.Fatal(err)
	}
	defer func(readmeFile *os.File) {
		err := readmeFile.Close()
		if err != nil {
			log.Fatal(err)
		}
	}(readmeFile)

	err = readme.Execute(readmeFile, readmeTemplate)
	log.Printf("--> Building template: %s", readme.ParseName)
	if err != nil {
		log.Fatalln(err)
	} else {
		log.Printf("Build complete: %s", readmeFile.Name())
	}

	// docs/CODE_OF_CONDUCT.md
	docsCocFile, err := os.Create(docsCocPath)
	if err != nil {
		log.Fatal(err)
	}
	defer func(docsCocFile *os.File) {
		err := docsCocFile.Close()
		if err != nil {
			log.Fatal(err)
		}
	}(docsCocFile)
	log.Printf("--> Building template: %s", docsCodeOfConduct.ParseName)
	docsCocTemplate := DocsCodeOfConduct{RepoSlug: ghSlug}

	err = docsCodeOfConduct.Execute(docsCocFile, docsCocTemplate)
	if err != nil {
		log.Fatalln(err)
	} else {
		log.Printf("Build complete: %s", docsCocFile.Name())
	}

	// docs/CONTRIBUTING.md
	docsContributingFile, err := os.Create(docsContributingPath)
	if err != nil {
		log.Fatal(err)
	}
	defer func(docsContributingFile *os.File) {
		err := docsContributingFile.Close()
		if err != nil {
			log.Fatal(err)
		}
	}(docsContributingFile)
	log.Printf("--> Building template: %s", docsContributing.ParseName)
	docsContributingTemplate := DocsContributing{RepoName: ghRepo, RepoSlug: ghSlug}

	err = docsContributing.Execute(docsContributingFile, docsContributingTemplate)
	if err != nil {
		log.Fatalln(err)
	} else {
		log.Printf("Build complete: %s", docsContributingFile.Name())
	}

	// docs/SECURITY.md
	docsSecurityFile, err := os.Create(docsSecurityPath)
	if err != nil {
		log.Fatal(err)
	}
	defer func(docsSecurityFile *os.File) {
		err := docsSecurityFile.Close()
		if err != nil {
			log.Fatal(err)
		}
	}(docsSecurityFile)
	log.Printf("--> Building template: %s", docsSecurity.ParseName)
	docsSecurityTemplate := DocsSecurity{RepoName: ghRepo, RepoSlug: ghSlug}

	err = docsSecurity.Execute(docsSecurityFile, docsSecurityTemplate)
	if err != nil {
		log.Fatalln(err)
	} else {
		log.Printf("Build complete: %s", docsSecurityFile.Name())
	}
}

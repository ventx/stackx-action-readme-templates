.SHELLFLAGS = -ec
.ONESHELL:
.DEFAULT_GOAL := help

IMG_BACKEND ?= localhost:5001/stackx-backend:0.0.0
IMG_CONTROLLER ?= localhost:5001/stackx-controller:0.0.0
IMG_FRONTEND ?= localhost:5001/stackx-frontend:0.0.0
K8S_VERSION = 1.25.6
OS := $(shell uname -s | tr A-Z a-z)
SCHEMA_URL := https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master

ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\n\033[48;5;17m\033[1m\stackx Makefile\033[0m\n\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: dev
dev: minikube-start docker-build-dev dep-deploy minikube-load minikube-deploy ## Starts complete development environment.

tmux: ## Start a tmux session and within the development environment.
	@cd ../stackx-backend && ./hack/tmux.sh
	@printf "\033[36m make $@\033[0m: Finished\n"


##@ Backend (back, b)

.PHONY: b-build
b-build: back-build
.PHONY: back-build
back-build: ## Build Golang binary from code.
	@printf "\nBACKEND - Run go build ..."
	@cd ../stackx-backend && go build -o stackx-backend main.go
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-doc
b-doc: back-doc
.PHONY: back-doc
back-doc: ## Build Swagger/OpenAPI documentation.
	@printf "\nBACKEND - Generating swagger docs ..."
	@cd ../stackx-backend && swag init -g main.go --output docs
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-deploy-kind
b-deploy-kind: back-deploy-kind
.PHONY: back-deploy-kind
back-deploy-kind: ## Deploy to K8s Kind cluster.
	@printf "\nBACKEND - Deploy to kind ..."
	@kubectl config set-context kind
	@cd ../stackx-backend && kubectl apply -f ci/manifest.yaml
	@kubectl rollout restart deployment stackx-backend -n stackx
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-docker-build
b-docker-build: back-docker-build
.PHONY: back-docker-build
back-docker-build: ## Build docker image.
	@printf "\nBACKEND - Build docker image ${IMG_BACKEND} ..."
	@cd ../stackx-backend && docker build -t ${IMG_BACKEND} .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-docker-buildx
b-docker-buildx: back-docker-buildx
.PHONY: back-docker-buildx
back-docker-buildx: ## Build and push multi-arch images with buildx.
	@printf "\nBACKEND - Build docker image ${IMG_BACKEND} ..."
	@cd ../stackx-backend && docker buildx build --push --platform linux/amd64,linux/arm64 --tag ${IMG_BACKEND} .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-docker-build-dev
b-docker-build-dev: back-docker-build-dev
.PHONY: back-docker-build-dev
back-docker-build-dev: ## Build development docker image with hot-reloading.
	@printf "\nBACKEND - Build custom dev image for minikube with hot-reloading ..."
	@printf "\nBACKEND: Copy stackx-controller ...\n"
	@cd ../stackx-backend && rm -rf ./stackx-controller && cp -rf ../stackx-controller . && docker build -t ${IMG_BACKEND} -f hack/Dockerfile .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-docker-push
b-docker-push: back-docker-push
.PHONY: back-docker-push
back-docker-push: ## Push Docker image to registry.
	@printf "\nBACKEND - Build custom dev image for minikube with hot-reloading ..."
	docker push ${IMG_BACKEND}
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-fmt
b-fmt: back-fmt
.PHONY: back-fmt
back-fmt: ## Format your code with go fmt.
	@printf "\nBACKEND - Run go fmt to format your code ..."
	@cd ../stackx-backend && go fmt ./...
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-go-get
b-go-get: back-go-get
.PHONY: back-go-get
back-go-get: ## Run go get -u for your go.mod file.
	@printf "\nBACKEND - Run go get -u to update all deps ..."
	@cd ../stackx-backend && go get -u
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-kind-load
b-kind-load: back-kind-load
.PHONY: back-kind-load
back-kind-load: ## Load Docker image into Kind cluster.
	@printf "\nBACKEND - Load image into kind cluster ..."
	@kind load docker-image ${IMG_BACKEND}
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-k-logs
b-k-logs: back-kubectl-logs
.PHONY: b-kubectl-logs
b-kubectl-logs: back-kubectl-logs
.PHONY: back-kubectl-logs
back-kubectl-logs: ## Blocks until canceled (Ctrl-C): Show logs of pods.
	@printf "\nBLOCKING: Showing logs of stackx-backend ...."
	@kubectl logs deploy/stackx-backend -n stackx
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-k-port
b-k-port: back-kubectl-port
.PHONY: b-kubectl-port
b-kubectl-port: back-kubectl-port
.PHONY: backend-kubectl-port
back-kubectl-port: ## Blocks until canceled (Ctrl+C): Port-Forward --> 8080
	@printf "\nBLOCKING: Port-forwarding to localhost:8080 ...\n"
	@kubectl port-forward svc/stackx-backend 8080:80 -n stackx
	@printf "\n\033[36m make $@\033[0m: Finished\n"

.PHONY: b-run
b-run: back-run
.PHONY: back-run
back-run: ## Runs your Golang code.
	@printf "\nBACKEND - Run go run ./main.go ...\n"
	@cd ../stackx-backend && go run ./main.go
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-test
b-test: back-test
.PHONY: back-test
back-test: ## Runs your Golang tests.
	@printf "\nBACKEND - Run go test ./...\n"
	@cd ../stackx-backend && go test ./...
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: b-vet
b-vet: back-vet
.PHONY: back-vet
back-vet: ## Run go vet against code.
	@printf "\nBACKEND - Run go test ./..."
	@cd ../stackx-backend && go vet ./...
	@printf "\033[36m make $@\033[0m: Finished\n"


##@ Controller (ctrl, c)

.PHONY: ctrl-build
ctrl-build: ## Build Golang code.
	@printf "\nCONTROLLER - Run go build ..."
	@cd ../stackx-controller && go build -o stackx-controller main.go
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-doc
ctrl-doc: ## Build Swagger/OpenAPI documentation.
	@printf "\nCONTROLLER - Generating swagger docs ..."
	@cd ../stackx-controller && swag init -g main.go --output docs
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-deploy-kind
ctrl-deploy-kind: ## Deploy to K8s Kind cluster.
	@printf "\nCONTROLLER - Deploy to kind ..."
	@kubectl config set-context kind
	@cd ../stackx-controller && kubectl apply -f ci/manifest.yaml
	@kubectl rollout restart deployment stackx-controller -n stackx
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-docker-build
ctrl-docker-build: ## Build docker image.
	@printf "\nCONTROLLER - Build docker image ${IMG_CONTROLLER} ..."
	@cd ../stackx-controller && docker build -t ${IMG_CONTROLLER} .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-docker-buildx
ctrl-docker-buildx: ## Build and push multi-arch images with buildx.
	@printf "\nCONTROLLER - Build docker image ${IMG_BACKEND} ..."
	@cd ../stackx-controller && docker buildx build --push --platform linux/amd64,linux/arm64 --tag ${IMG_BACKEND} .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-docker-build-dev
ctrl-docker-build-dev: ## Build development docker image with hot-reloading.
	@printf "\nCONTROLLER - Build custom dev image for minikube with hot-reloading ..."
	@cd ../stackx-controller && docker build -t ${IMG_CONTROLLER} -f hack/Dockerfile .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-docker-push
ctrl-docker-push: ## Push Docker image to registry.
	@printf "\nCONTROLLER - Build custom dev image for minikube with hot-reloading ..."
	docker push ${IMG_CONTROLLER}
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-fmt
ctrl-fmt: ## Run go fmt against code.
	@printf "\nCONTROLLER - Run go fmt to format your code ..."
	@cd ../stackx-controller && go fmt ./...
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-kind-load
ctrl-kind-load: ## Load Docker image into Kind cluster.
	@printf "\nCONTROLLER - Load image into kind cluster ..."
	@kind load docker-image ${IMG_CONTROLLER}
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-go-get
ctrl-go-get: ## Run go get -u on your go.mod file.
	@printf "\nCONTROLLER - Run go get -u to update all deps ..."
	@cd ../stackx-controller && go get -u
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-kubectl-logs
ctrl-kubectl-logs: ## Blocks until canceled (Ctrl-C): Show logs of pods.
	@printf "\nCONTROLLER: Showing logs of stackx-backend ...."
	@kubectl logs deploy/stackx-controller -n stackx
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-kubectl-port
ctrl-kubectl-port: ## Blocks until canceled (Ctrl+C): Port-Forward --> 8080
	@printf "\nCONTROLLER: Port-forwarding to localhost:8080 ...\n"
	@kubectl port-forward svc/stackx-controller 8080:80 -n stackx
	@printf "\n\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-run
ctrl-run: ## Runs your Golang code.
	@printf "\nCONTROLLER - Run go run ./main.go ..."
	@cd ../stackx-controller && go run ./main.go
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-test
ctrl-test: ## Runs your Golang tests.
	@printf "\nCONTROLLER - Run go test ./..."
	@cd ../stackx-controller && go test ./...
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: ctrl-vet
ctrl-vet: ## Run go vet against code.
	@printf "\nCONTROLLER - Run go test ./..."
	@cd ../stackx-controller && go vet ./...
	@printf "\033[36m make $@\033[0m: Finished\n"


##@ Frontend (front, f)

.PHONY: front-build
front-build: ## Build Javascript code.
	@printf "\nFRONTEND - Run npm build ..."
	@cd ../stackx-frontend && npm run build
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-deploy-kind
front-deploy-kind: ## Deploy to K8s Kind cluster.
	@printf "\nFRONTEND - Deploy to kind ..."
	@kubectl config set-context kind
	@cd ../stackx-front && kubectl apply -f ci/manifest.yaml
	@kubectl rollout restart deployment stackx-frontend -n stackx
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-docker-build
front-docker-build: ## Build docker image.
	@printf "\nFRONTEND - Build docker image ${IMG_FRONTEND} ..."
	@cd ../stackx-frontend && docker build -t ${IMG_FRONTEND} .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-docker-buildx
front-docker-buildx: ## Build and push multi-arch images with buildx.
	@printf "\nFRONTEND - Build docker image ${IMG_BACKEND} ..."
	@cd ../stackx-frontend && docker buildx build --push --platform linux/amd64,linux/arm64 --tag ${IMG_BACKEND} .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-docker-build-dev
front-docker-build-dev: ## Build development docker image with hot-reloading.
	@printf "\nFRONTEND - Build custom dev image for minikube with hot-reloading ..."
	@cd ../stackx-frontend && docker build -t ${IMG_FRONTEND} -f hack/Dockerfile .
	@printf "\033[36m make $@\033[0m: Finished\n"

.front: front-docker-push
front-docker-push: ## Push Docker image to registry.
	@printf "\nFRONTEND - Build custom dev image for minikube with hot-reloading ..."
	docker push ${IMG_FRONTEND}
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-fmt
front-fmt: ## Run npm run fmt against code.
	@printf "\nFRONTEND - Run go fmt to format your code ..."
	@cd ../stackx-frontend && npm run fmt
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-kind-load
front-kind-load: ## Load Docker image into Kind cluster.
	@printf "\nFRONTEND - Load image into kind cluster ..."
	kind load docker-image ${IMG_FRONTEND}
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-kubectl-logs
front-kubectl-logs: ## Blocks until canceled (Ctrl-C): Show logs of pods.
	@printf "\nFRONTEND: Showing logs of stackx-backend ...."
	@kubectl logs deploy/stackx-frontend -n stackx
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-kubectl-port
front-kubectl-port: ## Blocks until canceled (Ctrl+C): Port-Forward --> 3000
	@printf "\nFRONTEND: Port-forwarding to localhost:3000 ...\n"
	@kubectl port-forward svc/stackx-frontend 3000:80 -n stackx
	@printf "\n\033[36m make $@\033[0m: Finished\n"

.PHONY: front-start
front-start: ## Starts / runs your Javascript code.
	@printf "\nFRONTEND - Run npm run start ..."
	@cd ../stackx-frontend && npm run start
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: front-test
front-test: ## Runs your Javascript tests.
	@printf "\nFRONTEND - Run npm run test ..."
	@cd ../stackx-frontend && npm run test
	@printf "\033[36m make $@\033[0m: Finished\n"


##@ K8s / Helm

.PHONY: ct
ct: ## Run chart-testing for your chart.
	@printf "\nHELM - Run chart-testing ..."
	@ct lint --config ci/ct.yaml --chart-yaml-schema ci/chart_schema.yaml --lint-conf ci/lintconf.yaml
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: d-deploy
d-deploy: dep-deploy
.PHONY: dep-deploy
dep-deploy: ## Deploy depencencies (flux, tf-controller) to cluster.
	@printf "\nDeploy dependencies (flux, tf-controller) ..."
	@flux install
	@helm upgrade -i tf-controller tf-controller/tf-controller --namespace flux-system
	@cd ../stackx-controller && make install
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: h-lint
h-lint: helm-lint
.PHONY: helm-lint
helm-lint: ## Run helm lint for your chart.
	@printf "\nHELM - Run helm lint ..."
ifneq ("$(wildcard ci/values-test.yaml)","")
	@helm lint chart/$(CHART) -f ci/values-test.yaml
else
	@printf "Fallback using unit-test values (if any) ...\n"
	@helm lint chart/$(CHART) -f chart/$(CHART)/tests/values-test.yaml --strict
endif
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: kubeconform
kubeconform: ## Run kubeconform on your chart.
	@printf "\nHELM - Run kubeconform ..."
	@rm -rf manifests/*
	@helm template chart/$(CHART) --output-dir manifests -f ci/values-test.yaml
	@find manifests -name '*.yaml' | grep -v crd | xargs kubeconform -kubernetes-version $(KUBE_VERSION) --strict --schema-location ${SCHEMA_URL} --ignore-missing-schemas
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: kubesec
kubesec: ## Run kubesec on your chart.
	@printf "\nHELM - Run kubesec ..."
	@helm template chart/$(CHART) -f ci/values-test.yaml | kubesec scan -
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: kubescore
kubescore: ## Run kubescore on your chart.
	@printf "\nHELM - Run kubescore ..."
	@helm template chart/$(CHART) -f ci/values-test.yaml | kube-score score --exit-one-on-warning -o ci --ignore-test container-image-pull-policy -
	@echo "kube-score exited with $(.SHELLSTATUS)"
	@printf "\033[36m make $@\033[0m: Finished\n"


##@ Kind

.PHONY: kind-start
kind-start: ## Starts a new Kind cluster.
	@printf "\nStarting kind cluster ..."
	@kind create cluster --config=ci/kind.yaml
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: kind-delete
kind-delete: ## Deletes the Kind cluster.
	@printf "\nDelete kind cluster ..."
	@kind delete cluster
	@printf "\033[36m make $@\033[0m: Finished\n"


##@ Minikube (minikube, mk)

.PHONY: mk-deploy
mk-deploy: minikube-deploy
.PHONY: minikube-deploy
minikube-deploy: ## Deploy all components to Minikube.
	@printf "\nDeploy ALL to minikube ..."
	@minikube update-context -p stackx
	@printf "stackx-controller ..."
	@cd ../stackx-controller
	@kubectl apply -f ../stackx-controller/hack/manifest-minikube.yaml
	@kubectl rollout restart deployment stackx-controller -n stackx
	@printf "stackx-backend ..."
	@cd ../stackx-backend
	@kubectl apply -f ../stackx-backend/hack/manifest-minikube.yaml
	@kubectl rollout restart deployment stackx-backend -n stackx
	@printf "stackx-frontend ..."
	@cd ../stackx-frontend
	@kubectl apply -f ../stackx-frontend/ci/manifest.yaml
	@kubectl rollout restart deployment stackx-frontend -n stackx
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: mk-delete
mk-delete: minikube-delete
.PHONY: minikube-delete
minikube-delete: ## Delete the Minikube cluster.
	@printf "\nRemove / Delete all minikube resources ..."
	@minikube delete --all
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: mk-destroy
mk-destroy: minikube-destroy
.PHONY: minikube-destroy
minikube-destroy: ## Destroy and purge the Minikube cluster.
	@printf "\nDestroy and purge all minikube resources ..."
	@minikube delete --all --purge
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: mk-start
mk-start: minikube-start
.PHONY: minikube-start
minikube-start: ## Starts a new Minikube cluster.
	@printf "\nStarting minikube cluster ..."
	@minikube start --driver=docker --cpus=4 --memory=8192 --nodes 2 -p stackx --kubernetes-version=v${K8S_VERSION} --mount-string="$(shell dirname $$(pwd))/:/tmp/git" --mount
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: stop
stop: minikube-stop
.PHONY: mk-stop
mk-stop: minikube-stop
.PHONY: minikube-stop
minikube-stop: ## (stop) Stopping the Minikube cluster.
	@printf "\nStopping minikube cluster ..."
	@minikube stop -p stackx
	@printf "\033[36m make $@\033[0m: Finished\n"


##@ Terraform (tf, t)

.PHONY: t-apply
t-apply: tf-apply
.PHONY: tf-apply
tf-apply: ## Run terraform apply for your code.
	@printf "\nTERRAFORM - Run terraform apply ..."
	@terraform apply -auto-approve
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: t-clean
t-clean: tf-clean
.PHONY: tf-clean
tf-clean: ## Remove lockfiles and terraform states.
	@printf "\nTERRAFORM - Cleanup state and lockfiles ..."
	@rm -rf .terraform examples/.terraform examples/all/.terraform examples/non-k8s/.terraform tests/.terraform
	@rm -f terraform.tfstate* examples/terraform.tfstate* examples/all/terraform.tfstate* examples/non-k8s/terraform.tfstate*
	@rm -f .terraform.lock.hcl examples/.terraform.lock.hcl examples/all/.terraform.lock.hcl examples/non-k8s/.terraform.lock.hcl tests/.terraform.lock.hcl
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: t-destroy
t-destroy: tf-destroy
.PHONY: tf-destroy
tf-destroy: ## Run terraform destroy to delete all resources.
	@printf "\nTERRAFORM - Run terraform destroy ..."
	@terraform destroy -auto-approve
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: t-fmt
t-fmt: tf-fmt
.PHONY: tf-fmt
tf-fmt: ## Run terraform fmt to format your HCL code.
	@printf "\nTERRAFORM - Run terraform fmt ..."
	@terraform fmt -recursive
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: t-init
t-init: tf-init
.PHONY: tf-init
tf-init: ## Run terraform init for your code.
	@printf "\nTERRAFORM - Run terraform init ..."
	@terraform init
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: tflint
tflint: tf-lint
t-lint: tf-lint
.PHONY: t-lint
t-lint: tf-lint
.PHONY: tf-lint
tf-lint: ## Run tflint for your code.
	@printf "\nTERRAFORM - Run tflint ..."
	@tflint .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: tfsec
tfsec: tf-tfsec
.PHONY: t-tfsec
t-tfsec: tf-tfsec
.PHONY: tf-tfsec
tf-tfsec: ## Run tfsec for your code.
	@printf "\nTERRAFORM - Run tfsec ..."
	@tfsec .
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: t-local
t-local: tf-local-start
.PHONY: tf-local
tf-local: tf-local-start
.PHONY: tf-local-start
tf-local-start: ## Run localstack
	@printf "\nLOCALSTACK - Run localstack (detached in the background) ..."
	@localstack start -d
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: t-localf
t-localf: tf-local-startf
.PHONY: tf-localf
tf-localf: tf-local-startf
.PHONY: tf-local-startf
tf-local-startf: ## Run localstack in foreground
	@printf "\nBLOCKING - Run localstack (attach, blocking) ..."
	@localstack start
	@printf "\033[36m make $@\033[0m: Finished\n"


.PHONY: tf-local-stop
tf-local-stop: ## Stop localstack
	@printf "\nLOCALSTACK - Stop localstack ..."
	@localstack stop
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: t-plan
t-plan: tf-plan
.PHONY: tf-plan
tf-plan: ## Run terraform plan for your code.
	@printf "\nTERRAFORM - Run terraform plan ..."
	@terraform plan
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: t-test
t-test: tf-test
.PHONY: tf-test
tf-test: tf-test-init ## Run terratest for your code.
	@printf "\nTERRAFORM - Run terratest ..."
	@cd tests && go test -v -count 1 -short -timeout "30m" -parallel 16 `go list ./...`
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: tf-test-fast
tf-test-fast: ## Run terratest against localstack with 64 (tf-test: 16) parallel requests for your code.
	@printf "\nTERRAFORM - Run terratest against localstack with 64 parallel requests ...\n"
	@cd tests && go test -v -count 1 -short -timeout "10m" -parallel 64 `go list ./...`
	@printf "\033[36m make $@\033[0m: Finished\n"

tf-test-init:
ifeq (,$(wildcard ./tests/go.mod))
	cd tests && go mod init $(shell basename $(CURDIR))
endif

.PHONY: t-validate
t-validate: tf-validate
.PHONY: tf-validate
tf-validate: ## Run terraform validate for some basic HCL validation.
	@printf "\nTERRAFORM - Run terraform validate ..."
	@terraform validate
	@printf "\033[36m make $@\033[0m: Finished\n"


##@ ALL

.PHONY: start-dev
.PHONY: start
start: start-dev
start-dev: dev ## 🚀 (start) Starts Minikube, build & deploy ALL for dev (hot reload).

.PHONY: purge
purge: clean-all
.PHONY: clean-all
clean-all: minikube-destroy ## 🗑️  (clean, destroy, purge) Clean EVERYTHING (Docker, Minikube, Kind, binaries, ...)
	@printf "\nCleaning all ..."
	@kind delete cluster
	@docker system prune -a -f
	@docker images purge
	@docker stop $(docker ps -a -q)
	@docker rmi $(docker images -a -q) -f
	@docker rm $(docker ps -a -q)
	@docker volume prune -f
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: docker-build
docker-build: back-docker-build ctrl-docker-build front-docker-build ## Build all Docker images.
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: docker-build-dev
docker-build-dev: back-docker-build-dev ctrl-docker-build-dev front-docker-build-dev ## Build all development Docker images.
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: docker-push
docker-push: back-docker-push ctrl-docker-push front-docker-push ## Push all Docker images to registry.
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: logs
logs: ## Tail ALL logs with kubetail
	@printf "\nTail ALL logs with kubetail ..."
	@ kubetail '(backend|controller|frontend)' -e regex -n stackx
	@printf "\033[36m make $@\033[0m: Finished\n"

.PHONY: mk-load
mk-load: minikube-load
.PHONY: minikube-load
minikube-load: ## Loads all docker images into Minikube.
	@printf "\nLoad ALL images into minikube cluster ... (this will take a while)"
	@minikube image load ${IMG_BACKEND} -p stackx
	@minikube image load ${IMG_CONTROLLER} -p stackx
	@minikube image load ${IMG_FRONTEND} -p stackx
	@printf "\n\033[36m make $@\033[0m: Finished\n"

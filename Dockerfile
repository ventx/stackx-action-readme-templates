# Build the manager binary
FROM golang:1.18.4 as builder

ARG TARGETARCH
ARG TARGETOS

# Copy the Go Modules manifests
COPY go.mod /go.mod
COPY go.sum /go.sum

RUN mkdir /readme
RUN mkdir /docs
COPY templates/readme/*.md /readme/
COPY templates/docs/*.md /docs/

COPY entrypoint.sh /entrypoint.sh

# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go /main.go

# Build
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -a -o /main /main.go

FROM golang:1.18.4-alpine
LABEL org.opencontainers.image.authors="hans-joerg@ventx.de"
LABEL org.opencontainers.image.name="stackx-doc-templates"

COPY --from=builder /main /main
COPY --from=builder /entrypoint.sh /entrypoint.sh
COPY --from=builder /readme/*.md /readme/
COPY --from=builder /docs/*.md /docs/

ENTRYPOINT ["/entrypoint.sh"]

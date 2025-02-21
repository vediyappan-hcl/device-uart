.PHONY: build test clean prepare update docker

GO = CGO_ENABLED=0 GO111MODULE=on go
GOCGO=CGO_ENABLED=1 GO111MODULE=on go

MICROSERVICES=cmd/device-uart

.PHONY: $(MICROSERVICES)

DOCKERS=docker_device_uart
.PHONY: $(DOCKERS)

VERSION=$(shell cat ./VERSION 2>/dev/null || echo 0.0.0)
GIT_SHA=$(shell git rev-parse HEAD)
GOFLAGS=-ldflags "-X github.com/edgexfoundry/device-uart.Version=$(VERSION)"

build: $(MICROSERVICES)

build-nats:
	make -e ADD_BUILD_TAGS=include_nats_messaging build

tidy:
	go mod tidy

cmd/device-uart:
	$(GOCGO) build -tags "$(ADD_BUILD_TAGS)" $(GOFLAGS) -o $@ ./cmd

unittest:
	go test ./... -coverprofile=coverage.out

lint:
	@which golangci-lint >/dev/null || echo "WARNING: go linter not installed. To install, run make install-lint"
	@if [ "z${ARCH}" = "zx86_64" ] && which golangci-lint >/dev/null ; then golangci-lint run --config .golangci.yml ; else echo "WARNING: Linting skipped (not on x86_64 or linter not installed)"; fi

install-lint:
	sudo curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $$(go env GOPATH)/bin v1.51.2

test: unittest lint
	$(GOCGO) vet ./...
	gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")
	[ "`gofmt -l $$(find . -type f -name '*.go'| grep -v "/vendor/")`" = "" ]
	./bin/test-attribution-txt.sh

clean:
	rm -f $(MICROSERVICES)

docker: $(DOCKERS)

docker_device_uart:
	docker build \
		--label "git_sha=$(GIT_SHA)" \
		--build-arg ADD_BUILD_TAGS=$(ADD_BUILD_TAGS) \
		-t edgexfoundry/device-uart:$(GIT_SHA) \
		-t edgexfoundry/device-uart:$(VERSION)-dev \
		.

docker-nats:
	make -e ADD_BUILD_TAGS=include_nats_messaging docker

vendor:
	$(GO) mod vendor

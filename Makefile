VERSION := $(shell x=$$(git describe --tags) && echo $${x\#v} || echo unknown)
VERSION_SUFFIX := $(shell [ -z "$$(git status --porcelain --untracked-files=no)" ] || echo -dirty)
VERSION_FULL := $(VERSION)$(VERSION_SUFFIX)
LDFLAGS := "${ldflags:+$ldflags }-X main.version=${ver}${suff}"
BUILD_FLAGS := -ldflags "-X main.version=$(VERSION_FULL)"

CMDS := demo/demo ptimg/ptimg

GO_FILES := $(wildcard *.go)
ALL_GO_FILES := $(wildcard *.go */*.go)

all: build check

build: .build $(CMDS)

.build: $(GO_FILES)
	go build ./...
	touch $@

demo/demo: $(wildcard demo/*.go)
	cd $(dir $@) && go build $(BUILD_FLAGS) ./...

ptimg/ptimg: $(wildcard ptimg/*.go)
	cd $(dir $@) && go build $(BUILD_FLAGS) ./...

check: lint gofmt coverage

gofmt: .gofmt

.gofmt: $(ALL_GO_FILES)
	o=$$(gofmt -l -w .) && [ -z "$$o" ] || { echo "gofmt made changes: $$o"; exit 1; }
	touch $@

lint: .lint

.lint: $(ALL_GO_FILES)
	golangci-lint run --enable-all
	touch $@

test:
	go test -v ./...

coverage: coverage.html

coverage.html: coverage.txt
	go tool cover -html=coverage.txt -o coverage.html

coverage.txt: $(ALL_GO_FILES)
	go test -race -covermode=atomic -coverprofile coverage.txt ./...

debug:
	@echo VERSION=$(VERSION)
	@echo VERSION=$(VERSION_FULL)
	@echo CMDS=$(CMDS)

clean:
	rm -f $(CMDS) coverage.html coverage.txt .lint .build

.PHONY: debug check test gofmt clean coverage all lint build
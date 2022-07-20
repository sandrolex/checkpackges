.DEFAULT_GOAL := default

clean:
	@rm ./bin/*

default: install-deps build 

build: setup bin_dir
	@go build -o bin/checkpackages ./cmd/main.go

bin_dir: 
	@mkdir -p ./bin

install-deps: install-goimports

install-goimports:
	@if [ ! -f ./goimports ]; then \
		cd ~ && go get -u golang.org/x/tools/cmd/goimports; \
	fi

install: build
	@cp bin/checkpackages /usr/local/bin

setup:
	@go mod tidy \
		&& go mod vendor

.PHONY: setup clean build 

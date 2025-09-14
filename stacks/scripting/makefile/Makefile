SHELL := /bin/bash
.SILENT:

include common.mk
include config.mk

.PHONY: help hello build clean lint fmt

help:
	printf "Available targets:\n"
	printf "  make hello      # wypisz przywitanie\n"
	printf "  make build      # przykładowy build (echo)\n"
	printf "  make clean      # usuń artefakty\n"
	printf "  make lint       # przykładowy lint (echo)\n"
	printf "  make fmt        # przykładowy format (echo)\n"

hello:
	$(call info,Hello from $(APP_NAME) v$(VERSION))

build:
	$(call info,Building $(APP_NAME)...) ; sleep 0.1
	mkdir -p dist
	echo "artifact" > dist/$(APP_NAME)-$(VERSION).txt
	$(call ok,Build done: dist/$(APP_NAME)-$(VERSION).txt)

clean:
	$(call warn,Cleaning dist/)
	rm -rf dist

lint:
	$(call info,Running lint...) ; sleep 0.1
	$(call ok,No issues found)

fmt:
	$(call info,Formatting...) ; sleep 0.1
	$(call ok,Nothing to format)

.PHONY: hello
hello:
	@echo "Hello, World!"



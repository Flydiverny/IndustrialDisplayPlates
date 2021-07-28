SHELL         := /bin/bash
MAKEFLAGS     += --warn-undefined-variables
.SHELLFLAGS   := -euo pipefail -c

MOD_NAME := $(shell jq -r '.name' info.json)
VERSION := $(shell jq -r '.version' info.json)
GIT_VERSION := $(shell git describe --dirty --always | sed 's/-/./2' | sed 's/-/./2')
RELEASE_NAME := $(MOD_NAME)_$(VERSION)_$(GIT_VERSION)

.PHONY: clean

clean:
	rm -rf dist/

dist: clean
	mkdir -p dist
	rsync -r --exclude-from .makeignore . dist/$(RELEASE_NAME)
	zip -9qyr dist/$(RELEASE_NAME).zip dist/$(RELEASE_NAME)/
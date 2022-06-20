SHELL := /usr/bin/env bash -euo pipefail -c

export PROJECT_NAME := Docker Build Action
export REPO_URL     := https://github.com/hashicorp/actions-docker-build

.PHONY: test
test: bats-tests

# test/fast skips slow tests, useful in pre-push hooks.
.PHONY: test/fast
test/fast: export FAST=true
test/fast: test

.PHONY: testdata
testdata: export UPDATE_TESTDATA=true
testdata: test

BATS := bats

.PHONY: bats-tests
bats-tests:
	cd scripts && $(BATS) .

.PHONY: example
example:
	@# placeholder

include dev.mk

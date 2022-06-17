SHELL := /usr/bin/env bash -euo pipefail -c

export PROJECT_NAME := Docker Build Action
export REPO_URL     := https://github.com/hashicorp/actions-docker-build

.PHONY: test
test: bats-tests

.PHONY: testdata
testdata: export UPDATE_TESTDATA=true
testdata: test

.PHONY: bats-tests
bats-tests:
	cd scripts && bats .

.PHONY: example
example:
	@# placeholder

include dev.mk

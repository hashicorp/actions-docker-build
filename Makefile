SHELL := /usr/bin/env bash -euo pipefail -c

.PHONY: test
test: bats-tests

.PHONY: testdata
testdata: export UPDATE_TESTDATA=true
testdata: test

.PHONY: bats-tests
bats-tests:
	cd scripts && bats .

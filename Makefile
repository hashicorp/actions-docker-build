SHELL := /usr/bin/env bash -euo pipefail -c

BATS_FILES := $(shell find scripts -mindepth 1 -maxdepth 1 -name '*.bats')
.PHONY: $(BATS_FILES)

.PHONY: test
test: bats-tests

.PHONY: bats-tests
bats-tests: $(BATS_FILES)
	for T in $^; do ( cd scripts && bats $$(basename $$T); ); done


SHELL := /usr/bin/env bash -euo pipefail -c

.PHONY: test
test: bats-tests

.PHONY: testdata
testdata: export UPDATE_TESTDATA=true
testdata: test

.PHONY: bats-tests
bats-tests:
	cd scripts && bats .


.PHONY: workflow-test
workflow-test:
	@act --rm --artifact-server-path "${TMPDIR}$(@)" --workflows ./.github/workflows/test.yml

# Dynamically create test targets for our workflow actions
# Each target is named after the job itself
# function for creating a target
define create_target
.PHONY: $(1)
$(1):
	@echo '==> Testing workflow job: `$$@`'
	@act --rm --artifact-server-path "$${TMPDIR}$$(@)" --workflows ./.github/workflows/test.yml --job $$(@)
endef

workflow_action_targets := $(shell egrep --only-match '^  (action-test-.+):' .github/workflows/test.yml | egrep -o '(action-[^:]+)')
# create the dynamic targets
$(foreach target,$(workflow_action_targets),$(eval $(call create_target,$(target))))

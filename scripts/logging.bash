# Copyright IBM Corp. 2021, 2025
# SPDX-License-Identifier: MPL-2.0

log()  { echo "==> $*" 1>&2; }
info() { log "$(bold_green "INFO: "   ) $(bold "$*")"; } 
warn() { log "$(bold_red   "WARNING: ") $(bold "$*")"; }
err()  { log "$(bold_red   "ERROR: "  ) $(bold "$*")"; return 1; }
die()  { log "$(bold_red   "FATAL: "  ) $(bold "$*")"; exit 1; }

styled_text() { ATTR="$1"; shift; echo -en '\033['"${ATTR}m$*"'\033[0m'; }

bold()       { styled_text "1"    "$*"; }
blue()       { styled_text "94"   "$*"; }
bold_blue()  { styled_text "1;94" "$*"; }
red()        { styled_text "91"   "$*"; }
bold_red()   { styled_text "1;91" "$*"; }
bold_green() { styled_text "1;92" "$*"; }

log_bold() { log "$(bold_blue "$*")"; }

# should_emit_gha_workflow_commands checks if we're running in GitHub
# and that we're not running in a BATS test. We only want to emit these
# commands outside of BATS tests in GitHub Actions, otherwise they
# pollute stdout, adding noise and breaking some tests.
should_emit_gha_workflow_commands() {
	[ "${GITHUB_ACTIONS:-}" != "true" ] && [ -z "${BATS_TEST_NAME:-}" ]
}

# group_start begins a GitHub Actions log group.
group_start() {
	should_emit_gha_workflow_commands || return 0
	echo "::group::$(bold "$*")"
}

# group_end begins a GitHub Actions log group.
group_end() {
	should_emit_gha_workflow_commands || return 0
	echo "::endgroup::"
}

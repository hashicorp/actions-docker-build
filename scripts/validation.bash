# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

log() { echo "$*" 1>&2; }

OLD_REDHAT_TAG_PREFIX="scan.connect.redhat.com/"

REDHAT_TAG_PREFIX="quay.io/redhat-isv-containers/"
REDHAT_TAG_PATTERN='^quay\.io\/redhat-isv-containers\/[0-9a-f]+:[^[:space:]]+$'

is_not_old_redhat_tag() {
	[[ $1 == $OLD_REDHAT_TAG_PREFIX* ]] || return 0
	log "Error: found a tag beginning '$OLD_REDHAT_TAG_PREFIX'."
	log "This tag format has been deprecated, please use a tag beginning '$REDHAT_TAG_PREFIX'."
	return 1
}

is_not_redhat_tag() {
	[[ $1 == $REDHAT_TAG_PREFIX* ]] || return 0
	log "Error: found a tag beginning '$REDHAT_TAG_PREFIX' in the tags input."
	log "A tag matching this pattern may be set in the redhat_tag input."
	return 1
}

is_valid_redhat_tag() {
	grep -qE "${REDHAT_TAG_PATTERN}" <<< "$1" && return 0
	log "Error: redhat_tag must match the pattern '$REDHAT_TAG_PATTERN'"
	log "Other tags must go in either the 'tags' or 'dev_tags' input."
	return 1
}

tags_validation() {
	for TAG in $1; do
		is_not_redhat_tag "$TAG" && continue
		return 1
	done
}

redhat_tag_validation() {
	[[ -z "$1" ]] && return 0
	is_not_old_redhat_tag "$1" && is_valid_redhat_tag "$1"
}

DEV_TAG_PATTERN='^(docker\.io/)?hashicorppreview/.*'

# Validates dev_tags for DockerHub only pushes to "hashicorppreview" org
dev_tags_validation() {
    [ -z "${1}" ] && return 0

    invalid_tags=()

    # Loop through each tag by processing the multi-line string
    while IFS= read -r dt; do
        dt=$(echo "$dt" | xargs)  # Trim leading/trailing whitespace
        # Skip empty lines
        [ -z "$dt" ] && continue

        log $dt

        # Validate each tag
        if ! grep -qE "$DEV_TAG_PATTERN" <<<"$dt"; then
            # Collect invalid tags
            invalid_tags+=("$dt")
        fi
    done <<< "$1"

    # If there are invalid tags, log the error and return 1.
    if [ ${#invalid_tags[@]} -ne 0 ]; then
        log "dev_tags must begin with 'hashicorppreview/' or 'docker.io/hashicorppreview/'. Invalid tags: ${invalid_tags[*]}"
        return 1
    fi

    return 0
}

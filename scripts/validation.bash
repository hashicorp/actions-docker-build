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
	for TAG in $1; do
		is_not_old_redhat_tag "$TAG" && is_valid_redhat_tag "$TAG" && continue
		return 1
	done
}

DEV_TAG_PATTERN='^(docker\.io/)?hashicorppreview/.*'

# Validates dev_tags for DockerHub only pushes to "hashicorppreview" org
dev_tags_validation() {
	[ -z "${1}" ] && return 0
	for dt in ${1}; do
		# dev_tags can only push to the 'hashicorppreview' dockerhub org
		grep -qE "$DEV_TAG_PATTERN" <<<"$dt" && continue
		log "dev_tags must begin with 'hashicorppreview/' or 'docker.io/hashicorppreview/' (Got: $dt)"
		return 1
	done
}

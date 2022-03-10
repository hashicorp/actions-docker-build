#!/usr/bin/env bash

set -Eeuo pipefail

log() { echo "$1" 1>&2; }

# Validates dev_tags for DockerHub only pushes to "hashicorppreview" org
dev_tags_validation() {
  if [ -n "${1}" ]; then
    for dt in ${1}; do
      # dev_tags can only push to the 'hashicorppreview' dockerhub org
      if ! grep -E "^(docker\.io/)?hashicorppreview/.*" <<<"$dt"; then
        log "dev_tags must begin with 'hashicorppreview/' or 'docker.io/hashicorppreview/' (Got: $dt)"
        return 1
      fi
    done
  fi
}

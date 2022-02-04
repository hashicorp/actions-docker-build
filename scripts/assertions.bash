# This file contains functions for making assertions about docker tag existence
# both in the local daemon and in specific tarballs.

tag_exists() {
	docker inspect "$1" > /dev/null 2>&1  && return 0
	return 1
}

assert_tag_exists_locally() {
	tag_exists "$1" && return 0
	echo "Assertion failed: tag $1 missing."
	return 1
}

assert_tags_exist_locally() {
	for T in "$@"; do
		assert_tag_exists_locally "$T"
	done
}

assert_tag_does_not_exist_locally() {
	tag_exists "$1" || return 0
	echo "Assertion failed: tag $1 exists, but it should not."
	return 1
}

assert_tags_do_not_exist_locally() {
	for T in "$@"; do
		assert_tag_does_not_exist_locally "$T"
	done
}

remove_tags() { docker rmi "$@" > /dev/null 2>&1 || true; }

tarball_tag_check_prep() { TARBALL="$1"; shift
	[ -f "$TARBALL" ] || {
		echo "Tarball not found: $TARBALL"
		return 1
	}
	remove_tags "$@"
	assert_tags_do_not_exist_locally "$@"
	docker load -i "$TARBALL"
}

assert_tarball_contains_tags() { TARBALL="$1"; shift
	tarball_tag_check_prep "$TARBALL" "$@"
	assert_tags_exist_locally "$@"
}

assert_tarball_not_contains_tags() { TARBALL="$1"; shift
	tarball_tag_check_prep "$TARBALL" "$@"
	assert_tags_do_not_exist_locally "$@"
}

assert_is_binfmt_registered() { 
  test -f "/proc/sys/fs/binfmt_misc/$1"
}

assert_binfmt_fix_binary_flag_is_set() {
  local flags
  IFS=":" read _ flags <<< $(grep "flags" /proc/sys/fs/binfmt_misc/$1)
  grep --quiet "F" <<< "$flags"
}

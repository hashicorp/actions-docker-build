setup() {
	set_all_env_vars

	TEST_ROOT="testdata/input"

	# Get test relative paths to tarballs, needed for assertions,
	# and remove them now so tests don't read stale tarballs.
	export TARBALL_PATH="$TEST_ROOT/$TARBALL_NAME"
	export DEV_TARBALL_PATH="$TEST_ROOT/$DEV_TARBALL_NAME"
	rm -rf "$DEV_TARBALL_PATH"
	rm -rf "$TARBALL_PATH"
}

set_all_required_env_vars() {
	export BIN_NAME=test_bin
	export VERSION=1.2.3
	export REVISION=cabba9e
	export DOCKERFILE=Dockerfile
	export TARGET=default
	export TARBALL_NAME=blahblah.docker.tar
	export PLATFORM="linux/amd64"
	export AUTO_TAG="some/auto/tag:1.2.3-deadbeef"
	export TAGS="
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	"
}

set_all_optional_env_vars() {
	export WORKDIR=""
	export DEV_TARBALL_NAME=blahblah.docker.dev.tar
	export DEV_TAGS=""
}

set_all_env_vars() {
	set_all_required_env_vars
	set_all_optional_env_vars
}

set_expected_tags() {
	read -ra EXPECTED_TAGS <<< "$TAGS"
	EXPECTED_TAGS+=("$AUTO_TAG")	
}

each_expected_tag() {
	set_expected_tags
	for TAG in "${EXPECTED_TAGS[@]}"; do $@ "$TAG"; done
}

tag_exists() {
	docker inspect "$1" > /dev/null 2>&1  && return 0
	return 1
}

assert_tag_exists_locally() {
	tag_exists "$1" && return 0
	echo "Assertion failed: tag $1 missing."
	return 1
}

assert_tag_does_not_exist_locally() {
	tag_exists "$1" || return 0
	echo "Assertion failed: tag $1 exists, but it should not."
	return 1
}

assert_expected_tags_do_not_exist() { each_expected_tag assert_tag_does_not_exist_locally; }

assert_expected_tags_exist() { each_expected_tag assert_tag_exists_locally; }

remove_expected_tags() {
	each_expected_tag remove_tag
	each_expected_tag assert_tag_does_not_exist_locally
}

remove_tag() { docker rmi "$1" > /dev/null 2>&1 || true; }

assert_tags_exist() {
	for TAG in "$@"; do assert_tag_exists_locally "$TAG"; done
}

assert_tarball_contains_tags() { TARBALL="$1"; TAGS="$2"
	remove_local_tags "$2"
}

@test "only required env vars set - all prod and staging tags built" {
	

	# Execute the script under test: docker_build
	(
		cd "$TEST_ROOT"
		./docker_build
	)

	[ -f "$TARBALL_PATH" ] || {
		echo "Tarball not created: $TARBALL_PATH"
		return 1
	}

	# The docker build will have left behind all the tags in the local
	# daemon. We want to assert that they are contained inside the tarbal
	# though, so first remove them from the daemon so we can see if they
	# load back in from the tarball.
	remove_expected_tags

	# Run docker load to load the tarball.
	docker load -i "$TARBALL_PATH"	

	assert_expected_tags_exist
}

@test "dev tags provided - dev tags built" {

	DEVTAG1=dadgarcorp/repo1:1.2.3-dev
	DEVTAG2=dadgarcorp/repo1/dev:1

	export DEV_TAGS="
		$DEVTAG1
		$DEVTAG2
	"
	
	# Execute the script under test: docker_build
	(
		cd "$TEST_ROOT"
		./docker_build
	)


	[ -f "$DEV_TARBALL_PATH" ] || {
		echo "Tarball not created: $DEV_TARBALL_PATH"
		return 1
	}

	# The docker build will have left behind all the tags in the local
	# daemon. We want to assert that they are contained inside the tarbal
	# though, so first remove them from the daemon so we can see if they
	# load back in from the tarball.
	remove_tag "$DEVTAG1"
	remove_tag "$DEVTAG2"

	# Run docker load to load the tarball.
	docker load -i "$DEV_TARBALL_PATH"

	assert_tags_exist "$DEVTAG1" "$DEVTAG2"
}

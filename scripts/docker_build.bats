setup() {
	set_all_env_vars

	SCRIPT_ROOT="$PWD"
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
	export TAGS=""
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

assert_expected_tags_do_not_exist() { each_expected_tag assert_tag_does_not_exist_locally; }

assert_expected_tags_exist() { each_expected_tag assert_tag_exists_locally; }

remove_expected_tags() {
	each_expected_tag remove_tags
	each_expected_tag assert_tag_does_not_exist_locally
}

remove_tags() { docker rmi "$@" > /dev/null 2>&1 || true; }

assert_tags_exist() {
	for TAG in "$@"; do assert_tag_exists_locally "$TAG"; done
}

tarball_tag_check_prep() { TARBAL="$1"; shift
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

set_test_prod_tags() {
	PROD_TAG1=dadgarcorp/repo1:1.2.3
	PROD_TAG2=public.ecr.aws/dadgarcorp/repo1:1.2.3

	export TAGS="
		$PROD_TAG1
		$PROD_TAG2
	"
}

set_test_dev_tags() {
	DEV_TAG1=dadgarcorp/repo1:1.2.3-dev
	DEV_TAG2=dadgarcorp/repo1/dev:1

	export DEV_TAGS="
		$DEV_TAG1
		$DEV_TAG2
	"
}

@test "only prod tags set - all prod and staging tags built" {

	set_test_prod_tags
	
	# Execute the script under test: docker_build
	(
		cd "$TEST_ROOT"
		"$SCRIPT_ROOT/docker_build"
	)

	assert_tarball_contains_tags "$TARBALL_PATH" "$PROD_TAG1" "$PROD_TAG2" "$AUTO_TAG"
}

@test "prod and dev tags provided - prod, dev, and staging tags built" {

	set_test_prod_tags
	set_test_dev_tags
	
	# Execute the script under test: docker_build
	(
		cd "$TEST_ROOT"
		"$SCRIPT_ROOT/docker_build"
	)

	echo "Prod tarball contains prod tags and the auto tag."
	assert_tarball_contains_tags "$TARBALL_PATH" "$PROD_TAG1" "$PROD_TAG2" "$AUTO_TAG"

	echo "Dev tarball contains dev tags and the auto tag."
	assert_tarball_contains_tags "$DEV_TARBALL_PATH" "$DEV_TAG1" "$DEV_TAG2" "$AUTO_TAG"	

	echo "Dev tarball should not contain prod tags."
	assert_tarball_not_contains_tags "$DEV_TARBALL_PATH" "$PROD_TAG1" "$PROD_TAG2"

	echo "Prod tarball should not contain dev tags."
	assert_tarball_not_contains_tags "$TARBALL_PATH" "$DEV_TAG1" "$DEV_TAG2"
}

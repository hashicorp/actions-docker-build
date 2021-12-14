
set_all_required_env_vars() {
	export BIN_NAME=test_bin
	export VERSION=1.2.3
	export REVISION=cabba9e
	export DOCKERFILE=Dockerfile
	export TARGET=default
	export TARBALL_NAME=abc.tar
	export PLATFORM="linux/amd64"
	export AUTO_TAG="some/auto/tag:1.2.3-deadbeef"
	export TAGS="
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	"
}

set_all_optional_env_vars() {
	export WORKDIR="testdata/input"
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

assert_tag_exists_locally() { docker inspect "$1" 2>&1 > /dev/null; }
assert_tag_does_not_exist_locally() { ! assert_tag_exists_locally; }
assert_expected_tags_do_not_exist() { each_expected_tag assert_tag_does_not_exist_locally; }
assert_expected_tags_exist() { each_expected_tag assert_tag_exists_locally; }

remove_expected_tags() {
	each_expected_tag docker rmi
	assert_expected_tags_do_not_exist
}

@test "only required env vars set - all prod and staging tags built" {
	set_all_env_vars
	
	# Execute the script under test: docker_build
	./docker_build

	TARBALL_PATH="$WORKDIR/$TARBALL_NAME"

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

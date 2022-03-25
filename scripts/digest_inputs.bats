#!/usr/bin/env bats

# setup ensures that there's a fresh .tmp directory, gitignored,
# and sets the GITHUB_ENV variable to a file path inside that directory.
setup() {
	rm -rf ./.tmp
	export GITHUB_ENV=./.tmp/github.env
	mkdir -p ./.tmp
	echo "*" > ./.tmp/.gitignore
}

set_all_required_env_vars_and_tags() {
	export REPO_NAME=repo1
	export REVISION=cabba9e
	export VERSION=1.2.3
	export ARCH=amd64
	export TARGET=default
	export TAGS='
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'
}

set_all_optional_env_vars_empty() {
	export ARM_VERSION=
	export PKG_NAME=
	export WORKDIR=
	export ZIP_NAME=
	export BIN_NAME=
	export DEV_TAGS=
	export DOCKERFILE=
	export TAGS=
}

assert_exported_in_github_env() {
	VAR_NAME="$1"
	WANT="$2"

	GOT="$(source "$GITHUB_ENV.export" && echo "${!VAR_NAME}")"

	if ! [ "$GOT" = "$WANT" ]; then
		echo "Got $VAR_NAME='$GOT'; want $VAR_NAME='$WANT'"
		return 1
	fi
}

@test "only required env vars and tags set - required vars passed through unchanged" {

	set_all_required_env_vars_and_tags

	# Execute the script under test: digest_inputs
	./digest_inputs

	# Set the expected exported values of the required variables.
	assert_exported_in_github_env REPO_NAME "repo1"
	assert_exported_in_github_env REVISION  "cabba9e"
	assert_exported_in_github_env VERSION   "1.2.3"
	assert_exported_in_github_env ARCH      "amd64"
	assert_exported_in_github_env TARGET    "default"
	assert_exported_in_github_env TAGS '
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'
}

@test "only required env vars and tags set - optional variables set as expected" {
	set_all_required_env_vars_and_tags

	# Execute the script under test: digest_inputs
	./digest_inputs

	# Set the expected exported vaues of the optional variables.
	assert_exported_in_github_env ARM_VERSION ""
	assert_exported_in_github_env PKG_NAME    "repo1_1.2.3"
	assert_exported_in_github_env WORKDIR     ""
	assert_exported_in_github_env ZIP_NAME    "repo1_1.2.3_linux_amd64.zip"
	assert_exported_in_github_env BIN_NAME    "repo1"
	assert_exported_in_github_env DEV_TAGS    ""
	assert_exported_in_github_env DOCKERFILE  "Dockerfile"
}

@test "only required env vars and tags set - generated variables set as expected" {
	set_all_required_env_vars_and_tags

	# Execute the script under test: digest_inputs
	./digest_inputs

	assert_exported_in_github_env AUTO_TAG                   "repo1/default/linux/amd64:1.2.3_cabba9e"
	assert_exported_in_github_env BIN_NAME_GUESSED           "true"
	assert_exported_in_github_env ENTERPRISE_DETECTED        "false"
	assert_exported_in_github_env OS                         "linux"
	assert_exported_in_github_env PKG_NAME_GUESSED           "false"
	assert_exported_in_github_env PLATFORM                   "linux/amd64"
	assert_exported_in_github_env REPO_NAME_MINUS_ENTERPRISE "repo1"
	assert_exported_in_github_env TARBALL_NAME               "repo1_default_linux_amd64_1.2.3_cabba9e.docker.tar"
	assert_exported_in_github_env DEV_TARBALL_NAME           "repo1_default_linux_amd64_1.2.3_cabba9e.docker.dev.tar"
	assert_exported_in_github_env ZIP_LOCATION               "/dist/linux/amd64"
	assert_exported_in_github_env ZIP_NAME_GUESSED           "true"
}


# Assert that the file at GITHUB_ENV is exactly the same
# as we expect, byte-for-byte. (This is only verified in one test case, because
# it's likely to be fragile, but it's important that we validate this at least
# once becaue the format of that file is important to get right.)
@test "required env vars and tags set - GITHUB_ENV file written correctly" {
	set_all_required_env_vars_and_tags

	# Execute the script under test: digest_inputs
	./digest_inputs

	WANT_GITHUB_ENV="testdata/want/github.env"

	if "${UPDATE_TESTDATA:-false}"; then
		mkdir -p "$(dirname "$WANT_GITHUB_ENV")"
		cp "$GITHUB_ENV" "$WANT_GITHUB_ENV"
		echo "Test data updated."
	fi

	if ! diff "$GITHUB_ENV" "$WANT_GITHUB_ENV"; then
		echo "Unexpected GITHUB_ENV file, see above diff."
		return 1
	fi
}

@test "redhat_tag set but not tags / passed through correctly" {
	set_all_required_env_vars_and_tags

	TAGS=

	export REDHAT_TAG="scan.connect.redhat.com/ospid-cabba9e/lockbox:1"

	# Execute the script under test: digest_inputs
	./digest_inputs

	assert_exported_in_github_env REDHAT_TAG "scan.connect.redhat.com/ospid-cabba9e/lockbox:1"
}

assert_failure_with_message_when() { local MESSAGE="$1"; shift
	local OUTPUT
	if OUTPUT="$("$@" 2>&1)"; then
		echo "Command '$*' succeeded but should have failed."
		echo "Full output:"
		echo "$OUTPUT"
		return 1
	fi
	grep -qF "$MESSAGE" <<< "$OUTPUT" && {
		if ! "${DEBUG_TESTS:-false}"; then return; fi
		echo "DEBUG MODE; TEST PASSED! FAILING TO SEE THE OUTPUT:"
		echo "$OUTPUT"
		return 1
	}
	echo "Command '$*' failed correctly, but did not include expected error message."
	echo "Expected to find '$MESSAGE' in output:"
	echo "$OUTPUT"
	return 1

}

@test "redhat_tag and tags set / error" {
	set_all_required_env_vars_and_tags
	export REDHAT_TAG="blah"
	WANT_ERR="Must set either TAGS or REDHAT_TAG (not both)"
	assert_failure_with_message_when "$WANT_ERR" ./digest_inputs
}

@test "tags contains a redhat tag / error" {
	set_all_required_env_vars_and_tags
	export TAGS="scan.connect.redhat.com/some/image:1.2.3"
	WANT_ERR="found a tag beginning 'scan.connect.redhat.com/' in the tags input"
	assert_failure_with_message_when "$WANT_ERR" ./digest_inputs
}

@test "redhat_tag contains non-redhat tag / error" {
	set_all_required_env_vars_and_tags
	export REDHAT_TAG="docker.io/blarblah:1.2.3"
	unset TAGS
	WANT_ERR="redhat_tag must match the pattern"
	assert_failure_with_message_when "$WANT_ERR" ./digest_inputs
}

@test "redhat_tag contains whitespace / error" {
	set_all_required_env_vars_and_tags
	export REDHAT_TAG="scan.connect.redhat.com/some/image:1.2.3 scan.connect.redhat.com/blah/blah:1.2.3"
	unset TAGS
	WANT_ERR="redhat_tag must match the pattern"
	assert_failure_with_message_when "$WANT_ERR" ./digest_inputs
}


setup() {
	rm -rf ./.tmp
	export GITHUB_ENV=./.tmp/github.env
	mkdir -p ./.tmp
	echo "*" > ./.tmp/.gitignore
	set_all_required_env_vars	
}

set_all_required_env_vars() {
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
}

@test "only required env vars set - requires vars passed through unchanged" {
	set_all_required_env_vars

	# Execute the script under test: digest_inputs
	./digest_inputs

	# Read the variables exported by ./digest_inputs
	GOT_REPO_NAME="$(source "$GITHUB_ENV.export" && echo "$REPO_NAME")"
	GOT_REVISION="$(source "$GITHUB_ENV.export" && echo "$REVISION")"
	GOT_VERSION="$(source "$GITHUB_ENV.export" && echo "$VERSION")"
	GOT_ARCH="$(source "$GITHUB_ENV.export" && echo "$ARCH")"
	GOT_TARGET="$(source "$GITHUB_ENV.export" && echo "$TARGET")"
	GOT_TAGS="$(source "$GITHUB_ENV.export" && echo "$TAGS")"

	# Set the expected exported values of the required variables.
	WANT_REPO_NAME=repo1
	WANT_REVISION=cabba9e
	WANT_VERSION=1.2.3
	WANT_ARCH=amd64
	WANT_TARGET=default
	WANT_TAGS='
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'

	# Assert that each required variable is as expected.
	[ "$GOT_REPO_NAME" = "$WANT_REPO_NAME" ]
	[ "$GOT_REVISION" = "$WANT_REVISION" ]
	[ "$GOT_VERSION" = "$WANT_VERSION" ]
	[ "$GOT_ARCH" = "$WANT_ARCH" ]
	[ "$GOT_TARGET" = "$WANT_TARGET" ]
	[ "$GOT_TAGS" = "$WANT_TAGS" ]
}

@test "only required env vars set - optional variables set as expected" {
	set_all_required_env_vars

	# Execute the script under test: digest_inputs
	./digest_inputs

	# Get the exported vaues of the optional variables.
	GOT_ARM_VERSION="$(source "$GITHUB_ENV.export" && echo "$ARM_VERSION")"
	GOT_PKG_NAME="$(source "$GITHUB_ENV.export" && echo "$PKG_NAME")"
	GOT_WORKDIR="$(source "$GITHUB_ENV.export" && echo "$WORKDIR")"
	GOT_ZIP_NAME="$(source "$GITHUB_ENV.export" && echo "$ZIP_NAME")"
	GOT_BIN_NAME="$(source "$GITHUB_ENV.export" && echo "$BIN_NAME")"
	GOT_DEV_TAGS="$(source "$GITHUB_ENV.export" && echo "$DEV_TAGS")"
	GOT_DOCKERFILE="$(source "$GITHUB_ENV.export" && echo "$DOCKERFILE")"

	# Set the expected exported vaues of the optional variables.
	WANT_ARM_VERSION=""
	WANT_PKG_NAME="repo1_1.2.3"
	WANT_WORKDIR=""
	WANT_ZIP_NAME="repo1_1.2.3_linux_amd64.zip"
	WANT_BIN_NAME="repo1"
	WANT_DEV_TAGS=""
	WANT_DOCKERFILE="Dockerfile"

	# Assert that each optional variable is exported with expected value.
	[ "$GOT_ARM_VERSION" = "$WANT_ARM_VERSION" ]
	[ "$GOT_PKG_NAME" = "$WANT_PKG_NAME" ]
	[ "$GOT_WORKDIR" = "$WANT_WORKDIR" ]
	[ "$GOT_ZIP_NAME" = "$WANT_ZIP_NAME" ]
	[ "$GOT_BIN_NAME" = "WANT_BIN_NAME" ]
	[ "$GOT_DEV_TAGS" = "WANT_DEV_TAGS" ]
	[ "$GOT_DOCKERFILE" = "WANT_DOCKERFILE" ]
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

@test "only required env vars set - generated variables set as expected" {
	set_all_required_env_vars

	# Execute the script under test: digest_inputs
	./digest_inputs

	assert_exported_in_github_env AUTO_TAG "repo1/default/linux/amd64:1.2.3_cabba9e"
	assert_exported_in_github_env BIN_NAME_GUESSED "true"
	assert_exported_in_github_env ENTERPRISE_DETECTED "false"
	assert_exported_in_github_env OS "linux"
	assert_exported_in_github_env PKG_NAME_GUESSED "false"
	assert_exported_in_github_env PLATFORM "linux/amd64"
	assert_exported_in_github_env REPO_NAME_MINUS_ENTERPRISE "repo1"
	assert_exported_in_github_env TARBALL_NAME "repo1_default_linux_amd64_1.2.3_cabba9e.docker.tar"
	assert_exported_in_github_env ZIP_LOCATION "/dist/linux/amd64"
	assert_exported_in_github_env ZIP_NAME_GUESSED "true"
}


@test "only required env vars set - GITHUB_ENV file written correctly" {
	set_all_required_env_vars

	# Execute the script under test: digest_inputs
	./digest_inputs

	# Additionally, assert that the file at GITHUB_ENV is exactly the same
	# as we expect, byte-for-byte. (This is only verified in this test because
	# it's likely to be fragile, but it's important that we validate this at least
	# once becaue the format of that file is important to get right.)
	WANT_GITHUB_ENV="testdata/want/github.env"
	if ! diff "$GITHUB_ENV" "$WANT_GITHUB_ENV"; then
		echo "Unexpected GITHUB_ENV file, see above diff."
		return 1
	fi
}

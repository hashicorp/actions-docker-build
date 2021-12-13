
# setup ensures that there's a fresh .tmp directory, gitignored,
# and sets the GITHUB_ENV variable to a file path inside that directory.
setup() {
	rm -rf ./.tmp
	export GITHUB_ENV=./.tmp/github.env
	mkdir -p ./.tmp
	echo "*" > ./.tmp/.gitignore
}

set_all_required_env_vars() {
	export BIN_NAME=repo1
	export VERSION=1.2.3
	export REVISION=cabba9e
	export TARGET=default
	export TARBALL_NAME=abc.tar
	export PLATFORM="linux/amd64"
	export AUTO_TAG="some/auto/tag:1.2.3-deadbeef"
	export TAGS="
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	"
}

set_all_optional_env_vars_empty() {
	WORKDIR=""
	DEV_TAGS=""
}

@test "only required env vars set - all prod and staging tags built" {
	set_all_required_env_vars
	
	# Execute the script under test: docker_build
	./docker_build

	# TODO
	# Remove all expected tags from local daemon.
	# Run docker load to load the tarball.
	# Assert that expected tags have been loaded.	
}

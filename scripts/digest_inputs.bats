
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

@test "only required vars set - exported unchanged" {
	set_all_required_env_vars

	./digest_inputs

	GOT_REPO_NAME="$(source "$GITHUB_ENV.export" && echo "$REPO_NAME")"
	GOT_REVISION="$(source "$GITHUB_ENV.export" && echo "$REVISION")"
	GOT_VERSION="$(source "$GITHUB_ENV.export" && echo "$VERSION")"
	GOT_ARCH="$(source "$GITHUB_ENV.export" && echo "$ARCH")"
	GOT_TARGET="$(source "$GITHUB_ENV.export" && echo "$TARGET")"
	GOT_TAGS="$(source "$GITHUB_ENV.export" && echo "$TAGS")"

	WANT_REPO_NAME=repo1
	WANT_REVISION=cabba9e
	WANT_VERSION=1.2.3
	WANT_ARCH=amd64
	WANT_TARGET=default
	WANT_TAGS='
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'

	[ "$GOT_REPO_NAME" = "$WANT_REPO_NAME" ]
	[ "$GOT_REVISION" = "$WANT_REVISION" ]
	[ "$GOT_VERSION" = "$WANT_VERSION" ]
	[ "$GOT_ARCH" = "$WANT_ARCH" ]
	[ "$GOT_TARGET" = "$WANT_TARGET" ]
	[ "$GOT_TAGS" = "$WANT_TAGS" ]

	WANT_GITHUB_ENV="testdata/want/github.env"
	if ! diff "$GITHUB_ENV" "$WANT_GITHUB_ENV"; then
		echo "Unexpected GITHUB_ENV file, see above diff."
		return 1
	fi

}

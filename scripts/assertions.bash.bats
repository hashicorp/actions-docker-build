#!/usr/bin/env bats

load assertions

BLANK_TAG="actions-docker-build/test:_blank"
WORKDIR="testdata/assertions/.tmp"

build_blank_image() {
	# This image isn't completely blank because completely blank images
	# aren't able to be exported via 'docker save', so we just copy in
	# whatever's in the WORKDIR to get around this.
	docker build -t "$BLANK_TAG" -f - . <<< "
		FROM scratch
		COPY * ./
	"
}

make_blank_workdir() {
	rm -rf "$WORKDIR"
	mkdir -p "$WORKDIR"
	cd "$WORKDIR"
	echo "*" > ".gitignore"
}

setup() {
	make_blank_workdir
	build_blank_image
}

@test "validate assert_tag_exists_locally" {
	assert_tag_exists_locally "$BLANK_TAG"
	docker rmi "$BLANK_TAG"
	if assert_tag_exists_locally "$BLANK_TAG"; then
		echo "Failed: deleted tag detected as existing."
	fi
}

@test "validate assert_tags_exist_locally" {
	assert_tags_exist_locally "$BLANK_TAG"
	docker rmi "$BLANK_TAG"
	if assert_tags_exist_locally "$BLANK_TAG"; then
		echo "Failed: deleted tag detected as existing."
	fi
}

@test "validate assert_tag_does_not_exist_locally" {
	if assert_tag_does_not_exist_locally "$BLANK_TAG"; then
		echo "Failed: existing tag detected as not existing."
	fi	
	docker rmi "$BLANK_TAG"
	assert_tag_does_not_exist_locally "$BLANK_TAG"
}

@test "validate assert_tags_do_not_exist_locally" {
	if assert_tags_do_not_exist_locally "$BLANK_TAG"; then
		echo "Failed: existing tag detected as not existing."
	fi	
	docker rmi "$BLANK_TAG"
	assert_tag_does_not_exist_locally "$BLANK_TAG"
}

@test "validate assert_tarball_contains_tags" {
	local TAGS=("${BLANK_TAG}_1" "${BLANK_TAG}_2" "${BLANK_TAG}_3")
	for T in "${TAGS[@]}"; do
		docker tag "$BLANK_TAG" "$T"
	done

	local TARBALL="tarball.tar"

	docker save -o "$TARBALL" "${TAGS[@]}"

	NONEXISTENT="this/tag/is/not/in/the/tarball:latest"

	# Assert checking all the tags are there at once works.
	assert_tarball_contains_tags "$TARBALL" "${TAGS[@]}"	
	
	# Assert each separate tag is there.
	assert_tarball_contains_tags "$TARBALL" "${TAGS[0]}"
	assert_tarball_contains_tags "$TARBALL" "${TAGS[1]}"	
	assert_tarball_contains_tags "$TARBALL" "${TAGS[2]}"

	# Assert failure when only provided tag doesn't exist.
	if assert_tarball_contains_tags "$TARBALL" "$NONEXISTENT"; then
		echo "Failed: assert_tarball_contains_tags reported tag exists that doesn't"
		return 1
	fi

	# Assert failure when one of the provided tags doesn't exist.
	if assert_tarball_contains_tags "$TARBALL" "${TAGS[@]}" "$NONEXISTENT"; then
		echo "Failed: assert_tarball_contains_tags reported tag exists that doesn't"
		return 1
	fi
}

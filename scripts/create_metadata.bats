#!/usr/bin/env bats

setup() {
	GOT="testdata/got/create_metadata"
	# Export OUT_DIR to tell create_metadata where to write the file.
	export OUT_DIR="$GOT/$BATS_TEST_NAME"

	# Create OUT_DIR and hide all of GOT from git.
	mkdir -p "$OUT_DIR"
	echo "*" > "$GOT/.gitignore"
}

assert_file_exists_in_dir() { local FILE="$1"; local DIR="$2"
	local WANT_FILEPATH="$DIR/$FILE"
	[ -f "$WANT_FILEPATH" ] || {
		echo "Missing file '$WANT_FILEPATH'; contents of $DIR:"
		ls -lah "$DIR"
		return 1
	}
}

@test "no dev tags" {
	export TAGS="
		tag1
		tag2
	"

	export TARGET="target1"

	WANT_FILENAME="docker_tag_list_target1.json"
	WANT_FILEPATH="$OUT_DIR/$WANT_FILENAME"

	WANT_JSON='{
		"dev_tags": [],
		"tags": [
			"tag1",
			"tag2"
		]
	}'

	# Run the script under test (create_metadata).
	./create_metadata

	# Assert file with expected name created.
	assert_file_exists_in_dir "$WANT_FILENAME" "$OUT_DIR"

	# Assert contents of file correct, ignoring whitespace.
	diff --ignore-all-space "$WANT_FILEPATH" - <<< "$WANT_JSON" > /dev/null 2>&1 || {
		echo "JSON not as expected."
		echo "Got:"
		cat "$WANT_FILEPATH"
		echo "Want:"
		echo "$WANT_JSON"
		return 1
	}

}

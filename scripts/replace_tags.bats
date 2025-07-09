#!/usr/bin/env bats

# Need 1.7.0 for run() to accept flags
# Note: need 1.7.0 for bats_require_minimum_version definition.
bats_require_minimum_version 1.7.0

# Rename bats' `run` function as `bats_run`.
# This must be in the current shell, so it cannot be within a bats setup* function.
eval "$(echo -n 'bats_run()' ; declare -f run | tail -n +2)"

# build an image for test purposes, but only if it doesn't already exist
__ensure_image() { local image="$1"
    if ! docker image inspect "$image" >/dev/null 2>&1 ; then
        (
            cd "$BATS_TEST_DIRNAME/testdata/input"
            docker build --tag="$TEST_IMAGE_TAG" --platform=linux/amd64 .
        )
    fi

    TEST_IMAGE_ID="$(docker image ls --format='{{.ID}}' "$TEST_IMAGE_TAG")"
    export TEST_IMAGE_ID
}

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert

    export TEST_IMAGE_TAG="replace_tags:testtag"
    __ensure_image "$TEST_IMAGE_TAG"
}

teardown() {
    if [ -z "$TEST_IMAGE_ID" ]; then
        echo "No TEST_IMAGE_ID defined, can't remove test image." 1>&2
        return 1
    fi

    echo "Removing test image: $TEST_IMAGE_ID" 1>&2
    docker image rm --force "$TEST_IMAGE_ID"
}

assert_tag_present() { local image="$1" tag="$2"
    local -a tags t
    read -a tags -r < <( docker image inspect "$image" | jq --raw-output '.[0].RepoTags[]' | xargs )
    for t in "${tags[@]}" ; do
        if [ "$t" == "$tag" ]; then
            return 0
        fi
    done
    echo "$tag: required tag is missing from image '$image'" 1>&2
    return 1 # not found
}

assert_tag_absent() { local image="$1" tag="$2"
    local -a tags t
    read -a tags -r < <( docker image inspect "$image" | jq --raw-output '.[0].RepoTags[]' | xargs )
    for t in "${tags[@]}" ; do
        if [ "$t" == "$tag" ]; then
            echo "$tag: found tag that must not be set for image '$image'" 1>&2
            return 1
        fi
    done
    return 0 # not found
}

## get_image_id

@test "get_image_id name:tag" {
    source "${BATS_TEST_DIRNAME}/replace_tags"
    bats_run -- get_image_id "$TEST_IMAGE_TAG"
    assert_output "$TEST_IMAGE_ID"
}

@test "get_image_id missing image" {
    local image_name_tag='replace-tags-no-such-image:no-such-tag'
    source "${BATS_TEST_DIRNAME}/replace_tags"
    bats_run -- get_image_id "$image_name_tag"
    assert_output --partial "$image_name_tag"
    assert_output --partial "image not found"
    assert_success # `docker image ls` returns 0 even when no image is found
}

## get_existing_tags

@test "get_existing_tags happy path" {
    local tag
    # add more tags so we can test fetching more than one
    local -a add_tags=( "extra_name1:extra_tag1" "extra_name1:extra_tag2" "extra_name2:extra_tag1" )
    for tag in "${add_tags[@]}" ; do
        docker image tag "$TEST_IMAGE_ID" "$tag"
    done

    source "${BATS_TEST_DIRNAME}/replace_tags"
    bats_run -- get_existing_tags "$TEST_IMAGE_ID"

    # check the number of tags found, but implicitly also test that we can slurp the output into an array
    local -a found_tags
    read -a found_tags -r <<< "$output"
    assert_equal "${#found_tags[*]}" $((1 + ${#add_tags[*]}))

    # check that each added tag was found
    for tag in "$TEST_IMAGE_TAG" "${add_tags[@]}" ; do
        assert_tag_present "$TEST_IMAGE_ID" "$tag"
    done
    assert_success
}

## add_tags

@test "add_tags happy path" {
    local tag
    local -a add_tags=( "extra_name1:extra_tag1" "extra_name1:extra_tag2" "extra_name2:extra_tag1" )

    # check the tags are absent so we don't think we added them when they were already there
    for tag in "${add_tags[@]}" ; do
        assert_tag_absent "$TEST_IMAGE_ID" "$tag"
    done

    source "${BATS_TEST_DIRNAME}/replace_tags"
    bats_run -- add_tags "$TEST_IMAGE_ID" "${add_tags[*]}"

    # check the tags are present
    for tag in "${add_tags[@]}" ; do
        assert_tag_present "$TEST_IMAGE_ID" "$tag"
    done
}

# This test induces a failure by specifying an invalid tag.  This is a proxy for
# other errors that could occur related to docker that are much harder to induce.
@test "add_tags failure" {
    local tag
    local -a add_tags=( "extra_name1:extra_tag1+moocow" )

    # check the tags are absent so we don't think we added them when they were already there
    for tag in "${add_tags[@]}" ; do
        assert_tag_absent "$TEST_IMAGE_ID" "$tag"
    done

    source "${BATS_TEST_DIRNAME}/replace_tags"
    bats_run -- add_tags "$TEST_IMAGE_ID" "${add_tags[*]}"
    assert_output --partial 'Error parsing reference'
    assert_failure
}

## remove_tags

@test "remove_tags happy path" {
    local tag
    local -a rm_tags=( "extra_name1:extra_tag1" "extra_name1:extra_tag2" "extra_name2:extra_tag1" )

    # check the tags are absent so we don't think we added them when they were already there
    for tag in "${rm_tags[@]}" ; do
        docker image tag "$TEST_IMAGE_ID" "$tag"
    done

    source "${BATS_TEST_DIRNAME}/replace_tags"
    bats_run -- remove_tags "$TEST_IMAGE_ID" "${rm_tags[*]}"

    # check the tags are present
    for tag in "${rm_tags[@]}" ; do
        assert_tag_absent "$TEST_IMAGE_ID" "$tag"
    done
    assert_success
}

@test "remove_tags missing tag" {
    local tag tag_missing="extra_name1:extra_tag1"

    source "${BATS_TEST_DIRNAME}/replace_tags"
    bats_run -- remove_tags "$TEST_IMAGE_TAG" "$tag_missing"
    assert_output --partial 'No such image'
    assert_output --partial "$tag_missing"
    assert_failure
}

## e2e

@test "main happy path" {
    local tag
    local -a initial_tags=( "initial1:tag1" "initial2:tag1" "initial2:tag2" )
    local -a final_tags=( "final1:tag1" "final1:tag2" "final2:tag1" )

    source "${BATS_TEST_DIRNAME}/replace_tags"
    # apply initial tags, verify
    bats_run -- add_tags "$TEST_IMAGE_TAG" "${initial_tags[*]}"
    for tag in "${initial_tags[@]}" ; do
        assert_tag_present "$TEST_IMAGE_ID" "$tag"
    done

    # replace the tags
    bats_run -- main "$TEST_IMAGE_TAG" "${final_tags[*]}"

    # final tags should be present
    for tag in "${final_tags[@]}" ; do
        assert_tag_present "$TEST_IMAGE_ID" "$tag"
    done
    # initial tags should be gone
    for tag in "${initial_tags[@]}" ; do
        assert_tag_absent "$TEST_IMAGE_ID" "$tag"
    done

    assert_success
}

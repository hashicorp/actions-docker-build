#!/usr/bin/env bats

load helpers

teardown() {
	unset DEV_TAGS
}

@test "assert valid dev_tags set" {
	export DEV_TAGS='
		hashicorppreview/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'

	run dev_tags_validation "$DEV_TAGS"
	[ $status -eq 0 ]
}

@test "assert invalid dev_tags set with no host" {
	export DEV_TAGS='
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'

	run dev_tags_validation "$DEV_TAGS"
	[ $status -eq 1 ]
	# [ "$output" = "Only valid DockerHub organization is 'hashicorppreview' (Got: dadgarcorp/repo1:1.2.3)" ]
}

@test "assert invalid dev_tags set with host docker.io" {
	export DEV_TAGS='
		docker.io/dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'

	run dev_tags_validation "$DEV_TAGS"
	[ $status -eq 1 ]
	# [ "$output" = "Only valid DockerHub organization is 'hashicorppreview' (Got: docker.io/dadgarcorp/repo1:1.2.3)" ]
}
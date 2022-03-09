#!/usr/bin/env bats

load helpers

@test "assert valid dev_tags set" {
	local DEV_TAGS='
		hashicorppreview/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'

	run dev_tags_validation "$DEV_TAGS"
	[ $status -eq 0 ]
}

@test "assert invalid dev_tags set with no host" {
	local DEV_TAGS='
		dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'

	run dev_tags_validation "$DEV_TAGS"
	[ $status -eq 1 ]
	[[ "$output" = *"dev_tags must begin with 'hashicorppreview/' or 'docker.io/hashicorppreview/'"* ]]
}

@test "assert invalid dev_tags set with host docker.io" {
	local DEV_TAGS='
		docker.io/dadgarcorp/repo1:1.2.3
		public.ecr.aws/dadgarcorp/repo1:1.2.3
	'

	run dev_tags_validation "$DEV_TAGS"
	[ $status -eq 1 ]
	[[ "$output" = *"dev_tags must begin with 'hashicorppreview/' or 'docker.io/hashicorppreview/'"* ]]
}
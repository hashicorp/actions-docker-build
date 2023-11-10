# Docker Build Action [![Heimdall](https://heimdall.hashicorp.services/api/v1/assets/actions-docker-build/badge.svg?key=b4d9245b2984d0d8c0ce7d59a1ff2eb41cf188cf5bef2d391d09c59b18c584b6)](https://heimdall.hashicorp.services/site/assets/actions-docker-build) [![CI](https://github.com/hashicorp/actions-docker-build/actions/workflows/test.yml/badge.svg)](https://github.com/hashicorp/actions-docker-build/actions/workflows/test.yml)

_For internal HashiCorp use only. The output of this action is specifically
designed to satisfy the needs of our internal deployment system, and may not be
useful to other organizations._

-----

Builds and tags a container image using Docker, enabling continuous delivery and
testing of container images in CRT.

-----

This action is used to build and tag a single-architecture Linux or Windows Docker image,
and save it as a tarball artifact. Typically the action is called multiple times
in a workflow, once for each target architecture, and thus multiple such tarball
artifacts are produced.

Downstream processes marry these single-architecture images together to produce
multi-architecture manifest lists ready for general consumption.

## Supported Registries

This action requires you to specify the fully-qualified tags to apply to each image.
Fully-qualified image tags (FQINs) contain the full image reference, including the
hostname or "registry" part.

Whilst _building_ isn't affected by what tags we apply locally, _pushing_ these images
is affected. Therefore you should only use tags for the following services:

- DockerHub `docker.io` (this is the default, you can optionally omit this hostname)
- AWS ECR Public `public.ecr.aws`
- Red Hat Certified Container Registry `scan.connect.redhat.com`
  (note there are special rules to follow when specifying `redhat_tag`, see below).

## Usage

### First Build Product Binaries

Because this action is designed to enable continuous delivery and testing of
container images, containing continuously delivered product binaries, the Dockerfile
must always COPY a _local_ product binary, rather than pulling a binary from
elsewhere. Therefore, prior to calling this action, you should have already built a
product binary matching the target platform of the docker image, zipped it
and stored it as an artifact using the [actions/upload-artifact@v2] action.

The name of the zip file artifact and the binary inside it are significant.

The zip file artifact must be saved as `<product_name>_<version>_<os>_<arch>.zip`
If not using this format, you can set the `zip_name` input to use a different one.

The product binary inside the zip file should match the name of the repository
containing it, minus any `-enterprise` suffix. If wanting to use another name,
you can set the `bin_name` input.

### Use a Matrix to Define Target Architectures

Since the action itself only builds a single image for a single architecture,
you must call it multiple times in order to build multiple architectures.

NOTE: If using the `redhat_tag` input, you must not use an architecture matrix,
see note on `redhat_tag` below.

### Action Inputs Explained

- **`version`** is the product version we are building a docker image for.
- **`revision`** is the revision that's being built.
  This may differ from the default <github.sha> which is the ref the action was invoked at.
- **`target`** is the name of the "stage" or "target" in the Dockerfile to build.
- **`arch`** is the architecture we're building for.
- **`tags`** is a newline-separated list of the "production tags" for this image.
  **Note that you must define the same tags for each architecture you're building,
  so the tag should never reference the architecture. See note below.**
- **`dev_tags`** is similar to **tags** except these tags are not intended for
  production/final releases; **dev_tags** are typically published much more
  frequently than production tags, and are used for early access to the latest code.
  Currently `dev_tags` must begin with `[docker.io/]hashicorppreview`.
- **`push_auto_dev_tags`** is a flag that can be passed in when calling the action to
  define whether the dev tags are pushed. Note that the default behaviour, when dev
  tags are defined, is to push dev tags:
  - PUSH_AUTO_DEV_TAGS=true & no dev-tags defined: push default dev tags
  - PUSH_AUTO_DEV_TAGS=true & dev-tags defined: push non-default dev tags
  - PUSH_AUTO_DEV_TAGS=false/empty & no dev-tags defined: do NOT push dev tags
  - PUSH_AUTO_DEV_TAGS=false/empty & dev-tags defined: push non-default dev tags
- **`redhat_tag`** allows specifying a Red Hat tag to apply to the image.
  NOTE: If you specify `redhat_tag` you may not also specify `tags` or `dev_tags`.
- **`smoke_test`** allows specifying a script to run immediately after the image
  is built, to perform some basic checks on the image. See note on `smoke_test` below.

#### Note on `target`

The `target` input is provided so that you can define multiple images inside the
same `Dockerfile`. Here is an example Dockerfile that defines two independent targets,
`target1` and `target2`:

```Dockerfile
FROM alpine:latest AS target1
# Lines omitted.

FROM ubuntu:latest AS target2
# Lines omitted.
```

(Note Docker documentation usually calles these 'stages' rather than 'targets', but
for our purposes, 'targets' describes how we use them more accurately.)

Sometimes you'll only want one release target (which must `COPY` a local product
binary inside it), and one "local dev" target which actually performs the build from
source for local development purposes. In this case you would only reference the
release target in the action configuration.

Some products need to produce multiple release Docker images. In this case, you
can reference each different image by its target name, in a separate call to this
action. You must be careful to ensure that the tags are different for images built
from different targets.

#### Note on `tags`

The `tags` and `dev_tags` you define are really the tags which are used for the
multi-arch manifest we construct later (not in this action). Therefore the `tags`
and `dev_tags` for a single image target must all be exactly the same, for all the
architectures.

In other words, never reference the `arch` inside the `tags` or `dev_tags` inputs.

#### Note on `redhat_tag`

If you specify `redhat_tag` then you can't also specify `tags` or `dev_tags`. Red Hat
Certified Container Image tags need special handling by downstream processes, and
do not support multiple architectures, so if needed, they must be built and tagged
separately.

Before using `redhat_tag` you will need to set up a project and obtain the project
ID, as well as the project-specific login key, which needs to be made available in
Vault under a specific path and key. There is internal-only documentation in the
wiki detailing how to do this.

#### Note on `smoke_test`

The `smoke_test` input accepts a bash script which will be run ater the image is built.
When the script is run, an environment variable called `IMAGE_NAME` is set to the name
of the image built. Your script can use this to run the image, e.g.

```
docker run "$IMAGE_NAME"
```

### Example Configuration

Here is a complete example workflow using this action. The same file is in this repo
at .github/workflows/example.yml and is executed on every push.

```yaml
name: example
on: [push]

env:
  product_name: actions-docker-build
  version: 1.0.0

defaults:
  run:
    shell: bash
    # Usually we would be in root, but this is just an example.
    working-directory: example/

jobs:

  build-product-binary:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - {go: "1.16", goos: "linux", goarch: "386"}
          - {go: "1.16", goos: "linux", goarch: "amd64"}
          - {go: "1.16", goos: "linux", goarch: "arm"}
          - {go: "1.16", goos: "linux", goarch: "arm64"}
          - {go: "1.16", goos: "freebsd", goarch: "386"}
          - {go: "1.16", goos: "freebsd", goarch: "amd64"}
          - {go: "1.16", goos: "windows", goarch: "386"}
          - {go: "1.16", goos: "windows", goarch: "amd64"}
          - {go: "1.16", goos: "solaris", goarch: "amd64"}
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Setup go
        uses: actions/setup-go@v2
        with:
          go-version: ${{ matrix.go }}
      - name: Compile Binary
        env:
          GOOS: ${{ matrix.goos }}
          GOARCH: ${{ matrix.goarch }}
        run: |
          go build -o "$product_name" .
          zip "${{ env.product_name }}_${{ env.version }}_${{ matrix.goos }}_${{ matrix.goarch }}.zip" "$product_name"
      - name: Upload product artifact.
        uses: actions/upload-artifact@v2
        with:
          path: example/${{ env.product_name }}_${{ env.version }}_${{ matrix.goos }}_${{ matrix.goarch }}.zip
          name: ${{ env.product_name }}_${{ env.version }}_${{ matrix.goos }}_${{ matrix.goarch }}.zip
          if-no-files-found: error

  build-product-docker-image:
    needs:
      - build-product-binary
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          # We only support building images for linux platforms,
          # so we only specify arch here.
          - {arch: "386"}
          - {arch: "amd64"}
          - {arch: "arm"}
          - {arch: "arm64"}
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Build
        uses: hashicorp/actions-docker-build@v1
        with:
          version: 1.0.0
          target: default
          arch: ${{ matrix.arch }}
          # Production tags. (These are the tags used for the multi-arch images
          # we eventually push, they must never be architecture/platform-specific.)
          tags: |
            docker.io/hashicorp/${{env.product_name}}:${{env.version}}
            public.ecr.aws/hashicorp/${{env.product_name}}:${{env.version}}
          # Dev tags are pushed more frequently by downstream processes. They also
          # must not reference the architecture.
          dev_tags: |
            docker.io/hashicorppreview/${{env.product_name}}:${{env.version}}-dev
          # Usually you wouldn't need to set workdir, but this is just an example.
          workdir: example/
```

## Artifacts

Each call to this action produces one metadata artifact as well as either one or two tarballs
containing a tagged single-arch docker image.

### Metadata: Tag List

The metadata file is a JSON blob containing three lists of tags generated by the call to the action.
The file is named either `docker_tag_list_${TARGET}.json` or `docker_tag_list_${TARGET}_redhat.json`.
The `TARGET` in these is the name of the Dockerfile target that was built.

If you're defining `redhat_tag` then the filename will have the `_redhat` suffix.

This tag list is used by downstream processes to quickly determine which tags were generated by
the build, so they know which remote registries they'll require credentials for when uploading.

Note that when calling this action in a matrix, each call will produce the same tag list file,
because its name and contents are not dependent on the architecture being built. This is by design,
the tags in this file are the user-facing tags which we will apply to the multi-arch manifest.

### Image Tarballs

The image tarballs are generated by calls to `docker save`. Each one contains the full single-arch
docker image, as well as all of the tags associated with that image. You will see that every image
has a special tag in addition to those defined by the action's inputs. This is called the "auto tag"
and its format uniquely identifies the single-arch image.

### Auto Tag

The "auto tag" is a semantic tag that identifies a single-arch image. It is used by downstream
processes that group sets of single-arch images into multi-arch manifests.

In order to create a multi-arch manifest from a set of single-arch images, downstream must call
`docker load` for each single-arch image tarball. Because the user-defined tags are the same for
each single-arch image, they cannot be used to differentiate the images loaded. Each `docker load`
call points all the user-defined tags to the new single-arch image. However, the auto-tag, being
different for each image, is retained after each `docker load` and can be used to identify which
images need to be stitched together using `docker manifest create`.

## FAQ
**Q: How do I create create a multi-arch manifest?**

A: Invoke `actions-docker-build` and to generate one image per platform and use the same tags for all of them. CRT will see the multiple images with the shared tag and merge them together into a manifest for publishing.

Here's an example that one manifest tag `1.0.0` with all the platforms:

```yaml
docker:
  strategy:
    matrix:
      include:
        - {arch: "386"}
        - {arch: "amd64"}
        - {arch: "arm"}
        - {arch: "arm64"}
  steps:
    - uses: hashicorp/actions-docker-build@latest
      with:
        version: 1.0
        arch: ${{matrix.arch}}
        tags: docker.io/hashicorp/my-product:1.0.0
```

In this example, in addition to the manifest list with all platforms `1.0.0-dev`, we also create per-arch tags. But generally, we would recommend pushing them in a combined set for a consistent look and feel for users.

```yaml
with:
  dev-tags:
     docker.io/hashicorppreview/my-product:1.0.0-dev
     docker.io/hashicorppreview/my-product:1.0.0-dev-${{matrix.arch}}
```

Background: Unfortunately the doocker output type does NOT support exporting multi-arch manifests. There is an OCI type but it does not yet support mulit-platform builds https://github.com/docker/roadmap/issues/371.

**Q: What happens when we are asked to create a manifest from two different images that share a tag but have the same platform?**

A: Previously, one of the images would get dropped/discarded. CRT will reject the publishing of a manifest list in this manner.

Background: Technically, we could publish them. However, what the end-user client does with that is up to them. The likely result, based on the [suggested algorithm](https://github.com/opencontainers/image-spec/issues/581#issuecomment-304668722) is:
> If there are more than one image manifests matching user's request, return an error.

So we fail the input by blocking publishing when this happens. If one has identified a situtation where this is useful behavior or the support is required, please let us know! We'd very much like to hear from you.

**Q: I am adding Windows Docker image support to my repo, but the workflow is throwing a `Must set VERSION` error. Why am I getting this error?**

A: There is a step in Docker build that calculate all the digest inputs. This calculation sets environment variables needed to build a Docker image and one of the variable is uppercase `VERSION`. Environment variables in Windows are not case-sensitive. If the build step defines the `version` variable in lower case, Windows thinks the `version` variable already exists so it does not set the upper case `VERSION` variable.

To fix this, make sure to set your `version` environment variable in the build step to a different name, something like `env-version`:

```yaml
  windows-docker:
    env:
      repo: ${{github.event.repository.name}}
      # this will fail, rename the variable
      # version: ${{needs.get-product-version.outputs.product-version}}
      env-version: ${{needs.get-product-version.outputs.product-version}}
    steps:
      - uses: hashicorp/actions-docker-build@latest
        with:
          version: ${{ env.env-version }}
```

**Q: How can I submit an image to multiple repositories?**

A: You need to define the following inputs in the `actions-docker-build` step: \
`tags:` to push to prod DockerHub and ECR registry \
`dev_tags:` to push to hashicorpreview \
`redhat_tag:` to push to Red Hat registry

**Q: How do I make sure tag X is also published as "latest"?**

A: CRT will update `latest` to the *first* tag in alphabetical order. The image must also have a `LABEL version=x.y.z` defined.

We do not currently support updating other aliases, if needed please add the appropriate tag to the build.

Before updating an alias, CRT will confirm the new image is a _newer_ version than the currently published under that alias. This check is performed by reading the `version` label on the image. Multi-image manifests must all have the same `version`.

Only stable releases will be allowed.

| New version     | Existing `latest` | Will update? |
| --------------- | ----------------- | ------------ |
| `1.0.0`         | (missing tag)     | ✅ |
| `1.0.0`         | (missing label)   | ✖️ |
| `1.0.0-rc1`     | `2.0.0`           | ⚠️ |
| `1.0.0-rc1`     | `1.0.0`           | ✔️ (noop) |
| `1.0.0`         | `2.0.0`           | ⚠️ |
| `2.0.5`         | `2.0.0`           | ✅ |
| (missing label) | `2.0.0`           | ✖️ |

## Releasing This Action

### Determine the New Version

To release a new version, first figure out what version you're releasing.
You can see the absolute [latest release](https://github.com/hashicorp/actions-docker-build/releases/latest)
or look at [all current releases](https://github.com/hashicorp/actions-docker-build/releases).

We use semantic versioning for this action. Therefore...

- If the release is expected to need additional action by users after upgrading,
  in order to preserve existing functionality, then it's classified as a breaking
  change, and the major version should be incremented (with the minor and patch
  both reset to 0.
- If the release adds additional new features that are opt-in but that can be safely
  ignored by users then the minor version should be incremented.
- If the release fixes a bug or alters logging or some other minor change that is very
  unlikely to break any existing usages of the action, then increment the patch version.

### Create the Release

Go to [draft a new release](https://github.com/hashicorp/actions-docker-build/releases/new).

- Use the version string from above, prefixed with `v` for the tag, e.g. `v1.2.3`.
- The title should be the same as the tag.
- Write a summary of changes to the best of your ability.
- If this is the highest overall version number, then select "set as latest release".
- Publish release.

### Push the change to users.

Currently, some users bind to `vX` and `vX.Y` tags, and expect these tags to be updated
so that they receive upgrades automatically. In order to do this:

Locally fetch the new tag created by the release:

```
git fetch vX.Y.Z
```

Add the new tags

```
git tag -f vX.Y vX.Y.Z
git tag -f vX vX.Y.Z
```

Push the new tags

```
git push origin vX.Y vX
```

And you're all done!

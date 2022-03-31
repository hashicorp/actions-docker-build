# Docker Build Action

_For internal HashiCorp use only. The output of this action is specifically
designed to satisfy the needs of our internal deployment system, and may not be
useful to other organizations._

-----

Builds and tags a container image using Docker, enabling continuous delivery and
testing of container images in CRT.

-----

This action is used to build and tag a single-architecture Linux Docker image,
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

### Action Inputs Explained

- **`version`** is the product version we are building a docker image for.
- **`target`** is the name of the "stage" or "target" in the Dockerfile to build.
- **`arch`** is the architecture we're building for.
- **`tags`** is a newline-separated list of the "production tags" for this image.
  **Note that you must define the same tags for each architecture you're building,
  so the tag should never reference the architecture. See note below.**
- **`dev_tags`** is similar to **tags** except these tags are not intended for
  production/final releases; **dev_tags** are typically published much more
  frequently than production tags, and are used for early access to the latest code.
  Currently `dev_tags` must begin with `[docker.io/]hashicorppreview`.
- **`redhat_tag`** allows specifying a Red Hat tag to apply to the image.
  NOTE: If you specify `redhat_tag` you may not also specify `tags` or `dev_tags`.

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

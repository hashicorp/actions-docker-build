# Docker Build Action

For internal HashiCorp use only.

This action is used to build and tag a single-architecture linux Docker image,
and save it as a tarball artifact. Typically the action is called multiple
times in a workflow, once for each target architecture, and thus multiple
such tarball artifacts are produced in typical usage.

The resultant artifacts are pulled by private downstream processes which
group them together as multi-arch maniefsts before publishing them.

## Usage

### First Build Product Binaries

For our purposes as HashiCorp, the product images we build must always COPY
a local product binary, rather than pulling a binary from elsewhere.
Therefore, prior to calling this action, you should have already built a 
product binary matching the target platform of the docker image, zipped it
and stored it as an artifact using the [actions/upload-artifact@v2] action.

The name of the zip file artifact and the binary inside it are significant.

The zip file artifact must be saved as `<product_name>_<version>_<os>_<arch>.zip`
If not using this format, you can set the `zip_name` parameter to use a different one.

The product binary inside the zip file should match the name of the repository
containing it, minus any `-enterprise` suffix. If wanting to use another name,
you can set the `bin_name` input.

### Use a Matrix to Define Target Architectures

Since the action itself only builds a single image for a single architecture,
you must call it multiple times in order to build multiple architectures.

### Action Inputs Explained

- **version** is the product version we are building a docker image for.
- **target** is the name of the "stage" or "target" in the Dockerfile to build.
- **arch** is the architecture we're building for.
- **tags** is a newline-separated list of the "production tags" for this image.
  **Note that you must define the same tags for each architecture you're building,
  so the tag should never reference the architecture. See note below.**
- **dev_tags** is similar to **tags** except these tags are not intended for
  production/final releases; **dev_tags** are typically published much more
  frequently than production tags, and are used for early access to the latest code.

### Example Configuration

Here is a complete example workflow using this action. The same file is in this repo
at .github/workflows/example.yml and is executed on every push.

```yaml
name: example
on: [push]

env:
  product_name: actions-docker-build

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
          zip "$product_name.zip" "$product_name"
      - name: Upload product artifact.
        uses: actions/upload-artifact@v2
        with:
          path: ${{ env.product_name }}_${{ env.version }}_${{ matrix.goos }}_${{ matrix.goarch }}.zip
          name: ${{ env.product_name }}_${{ env.version }}_${{ matrix.goos }}_${{ matrix.goarch }}.zip

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
            ${{env.TAG_PREFIX}}/action-test-setting-dockerfile:${{env.version}}-dev
          # Usually you wouldn't need to set workdir, but this is just an example.
          workdir: example/

```

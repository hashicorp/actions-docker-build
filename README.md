# Docker Build Action

For internal HashiCorp use only.

This action is used to build and tag a single-architecture linux Docker image,
and save it as a tarball artifact. Typically the action is called multiple
times in a workflow, once for each target architecture, and thus multiple
such tarball artifacts are produced in typical usage.

The resultant artifacts are pulled by private downstream processes which
group them together as multi-arch maniefsts before publishing them.

## Usage

### First Build the Product Binary

For our purposes as HashiCorp, the product images we build must always COPY
a local product binary, rather than pulling a binary from elsewhere.
Therefore, prior to calling this action, you should have already built the
product binary and stored it as an artifact using the [actions/upload-artifact@v2]
action.

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

TODO

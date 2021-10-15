# Changelog - Docker Build Action

## v1.1.0 (not yet released)

- Fixed: When setting `workdir:` that directory is used for downloading the binary
  artifact. This fixes the issue where it was possible to download the artifact
  to a place outside of the docker build context (i.e. where it was not accessible).

- Changed: No longer performs checkout, expects caller to have already checked out.
  This fixes an issue where mutations to the repository are needed prior to
  building. Note that this mutation is probably an anti-pattern, but it's not this
  action's responsibility to force users' hands one way or the other over this.

- Changed: Added some simple tests, see [.github/workflows/test.yml](tree/.github/workflows/test.yml).

## v1.0.1

- Changed: The automatic tags now include the `version`, matching the tarball name.

## v1.0.0

Initial version.

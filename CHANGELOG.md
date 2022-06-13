# Changelog - Docker Build Action

## v1.3.1

- Resolve issue where the internal auto tag was invalid with enterprise
  versions.

## v1.3.0

_No entries._

## v1.2.2

- Better handling of enterprise versions and complex version strings, e.g.
  `1.2.3+ent-fips.XYZ` now interpreted correctly.

## v1.2.1

- Fix for `REPO_NAME` not being set when calling the workflow from a schedule.`

## v1.2.0

- Fixing issue with docker buildx targeting arm cpus from amd64 host
- Add capability to run docker images smoke test in CI

## v1.1.0

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

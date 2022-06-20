#!/usr/bin/env bats

load assertions

setup() {
  SCRIPT_ROOT="$PWD"
}

skip_unless_run_destructive() {
  if [ "$RUN_DESTRUCTIVE_TESTS" != true ]; then
    skip "Not running destuctive tests; set RUN_DESTRUCTIVE_TESTS=true to run them."
  fi
}

# register_qemu_binfmt will mutate the underlying host system, which we don't want
#  to do without fair warning. In addition, on MacOS, this will either have no effect
#  on the DockerVM, as it's already configured that way, or it could possibly harm
#  the machine, if it was built with a different version of buildkit/qemu than what
#  this installs. If the setup has no effect, then the tests aren't actually useful.
#  In addition, testing the state of the DockerVM would require additional logic and
#  setup causing the local instances of the tests to differ from what would be run in
#  CI.  If it is desireable to run this particular test locally, it is recommended to
#  obtain a VM (ex: with Vagrant) and run this test suite with `RUN_DESTRUCTIVE_TESTS=true`
#  set in the environment.

@test "qemu-aarch64 is regesterd in binfmt_misc" {
  skip_unless_run_destructive

  "$SCRIPT_ROOT"/register_qemu_binfmt

  assert_binfmt_fix_binary_flag_is_set "qemu-aarch64"
  assert_is_binfmt_registered "qemu-aarch64"
}

@test "qemu-arm is registered in binfmt_misc" {
  skip_unless_run_destructive

  "$SCRIPT_ROOT"/register_qemu_binfmt

  assert_is_binfmt_registered "qemu-arm"
  assert_binfmt_fix_binary_flag_is_set "qemu-arm"
}

@test "qemu-se90x is registered in binfmt_misc" {
  skip_unless_run_destructive

  "$SCRIPT_ROOT"/register_qemu_binfmt

  assert_is_binfmt_registered "qemu-s390x"
  assert_binfmt_fix_binary_flag_is_set "qemu-s390x"
}

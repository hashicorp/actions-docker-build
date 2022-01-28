#!/usr/bin/env bats

load assertions

setup() {
  SCRIPT_ROOT="$PWD"
}

skip_unless_ci() {
  if [ "$CI" != true ]; then 
    skip
  fi
}

@test "qemu is registered in binfmt_misc" {
  # register_qemu_binfmt will mutate the underlying host system, which we don't want
  #  to do without fair warning. In addition, on MacOS, this will either have no effect
  #  on the DockerVM, as it's already configured that way, or it could possibly harm 
  #  the machine, if it was built with a different version of buildkit/qemu than what 
  #  this installs. If the setup has no effect, then the tests aren't actually useful. 
  #  In addition, testing the state of the DockerVM would require additional logic and 
  #  setup causing the local instances of the tests to differ from what would be run in 
  #  CI.  If it is desireable to run this particular test locally, it is recommended to
  #  obtain a VM (ex: with Vagrant) and run this test suite with `CI=true` set in the 
  #  environment
  skip_unless_ci

  "$SCRIPT_ROOT"/register_qemu_binfmt

  echo "qemu-aarch64 is registered under /proc/sys/fs/binfmt_misc"
  assert_is_binfmt_registered qemu-aarch64
  echo "qemu-arm is registered under /proc/sys/fs/binfmt_misc"
  assert_is_binfmt_registered qemu-arm
  echo "qemu-s390x is registered under /proc/sys/fs/binfmt_misc"
  assert_is_binfmt_registered qemu-s390x

  echo "The 'F' flag is set for qemu-aarch64"
  assert_binfmt_fix_binary_flag_is_set qemu-aarch64
  echo "The 'F' flag is set for qemu-s390"
  assert_binfmt_fix_binary_flag_is_set qemu-s390x
  echo "The 'F' flag is set for qemu-arm"
  assert_binfmt_fix_binary_flag_is_set qemu-arm
}  


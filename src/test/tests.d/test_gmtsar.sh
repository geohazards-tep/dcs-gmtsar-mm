#!/bin/bash

export ciop_job_include="/usr/lib/ciop/libexec/ciop-functions.sh"
source ./test_common.sh
source ../main/app-resources/gmtsar/lib/functions.sh

test_bash_n_run() {

  bash -n ../main/app-resources/gmtsar/run
  res=$?
  assertEquals "bash -n validation failed" \
  "0" "${res}"
}

test_bash_n_lib() {

  bash -n ../main/app-resources/gmtsar/lib/functions.sh
  res=$?
  assertEquals "bash -n validation failed" \
  "0" "${res}"

}

. ${SHUNIT2_HOME}/shunit2

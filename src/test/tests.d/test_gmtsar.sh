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

test_bash_n_lib_alos2() {

  bash -n ../main/app-resources/gmtsar/lib/functions_ALOS2.sh
  res=$?
  assertEquals "bash -n validation of functions_ALOS2.sh failed" \
  "0" "${res}"

}

test_bash_n_lib_tsx() {

  bash -n ../main/app-resources/gmtsar/lib/functions_TSX.sh
  res=$?
  assertEquals "bash -n validation of functions_TSX.sh failed" \
  "0" "${res}"

}

test_bash_n_lib_envisat() {

  bash -n ../main/app-resources/gmtsar/lib/functions_ENVISAT.sh
  res=$?
  assertEquals "bash -n validation of functions_ENVISAT.sh failed" \
  "0" "${res}"

}

test_bash_n_lib_s1() {

  bash -n ../main/app-resources/gmtsar/lib/functions_S1.sh
  res=$?
  assertEquals "bash -n validation of functions_S1.sh failed" \
  "0" "${res}"

}

. ${SHUNIT2_HOME}/shunit2

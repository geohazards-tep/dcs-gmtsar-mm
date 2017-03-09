#!/bin/bash

test_application() {

  xmllint --format ../main/app-resources/application.xml &> /dev/null
  res=$?
  assertEquals "xmllint validation failed" \
  "0" "${res}"

}

. ${SHUNIT2_HOME}/shunit2

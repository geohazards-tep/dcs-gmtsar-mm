#!/bin/bash

# source the ciop functions (e.g. ciop-log, ciop-getparam)
source ${ciop_job_include}
source ${_CIOP_APPLICATION_PATH}/node_B/lib/functions.sh

trap cleanExit EXIT

# Input references come from STDIN (standard input) and they are retrieved
# line-by-line.
while read input
do
  main || exit $?
done
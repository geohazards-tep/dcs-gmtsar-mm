#!/bin/csh -fx

master=$1
slave=$2

cd ${TMPDIR}/runtime

p2p_ALOS2_SLC.csh ${master} ${slave} ${_CIOP_APPLICATION_PATH}/gmtsar/etc/config.alos.slc.txt

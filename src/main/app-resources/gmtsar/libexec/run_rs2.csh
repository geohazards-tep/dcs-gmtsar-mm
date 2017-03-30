#!/bin/csh -fx

cd ${TMPDIR}/runtime

p2p_RS2_SLC.csh $1 $2 ${_CIOP_APPLICATION_PATH}/gmtsar/etc/config.rs2.txt

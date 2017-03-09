#!/bin/csh -fx

master=$1
slave=$2

cd ${TMPDIR}/runtime

p2p_TSX_SLC.csh ${master} ${slave} ${_CIOP_APPLICATION_PATH}/gmtsar/etc/config.tsx.txt

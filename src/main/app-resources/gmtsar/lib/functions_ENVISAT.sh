ERR_ENVISAT_DOR=80
ERR_ENVISAT_AUX=81
ERR_ENVISAT_PREP=82

function env_ENVISAT() {

  ciop-log "INFO" "Extending environment for ENVISAT ASAR"
 
  export OS=$( uname -p )
  export GMTHOME=/usr
  export NETCDFHOME=/usr
  export GMTSARHOME=/usr/local/GMTSAR
  export GMTSAR=${GMTSARHOME}/gmtsar
  export ENVIPRE=${GMTSARHOME}/ENVISAT_preproc
  export PATH=${GMTSAR}/bin:${GMTSAR}/csh:${GMTSARHOME}/preproc/bin:${GMTSARHOME}/ENVISAT_preproc/bin/:${GMTSARHOME}/ENVISAT_preproc/csh:${PATH}
  
#  export ENVIPRE=${GMTSARHOME}/ENVISAT_preproc
#  export PATH=${PATH}:${GMTSARHOME}/ENVISAT_preproc/bin/:${GMTSARHOME}/ENVISAT_preproc/csh
 
  mkdir -p ${TMPDIR}/aux/ENVI/ASA_INS
  mkdir -p ${TMPDIR}/aux/ENVI/Doris

  export ORBITS=${TMPDIR}/aux  

}


function get_aux_ENVISAT() {
  
  local joborder=$1
  local enclosure

  for doris in $( cat ${joborder} | sort -u | grep "^orb=" | cut -d "=" -f 2- )
  do
    enclosure=$( opensearch-client ${doris} enclosure )
    [ -z "${enclosure}" ] && ${ERR_ENVISAT_DOR}
    ciop-copy -O ${TMPDIR}/aux/ENVI/Doris ${enclosure}
    [ "$?" != "0" ] && return ${ERR_ENVISAT_DOR}
  done

  ciop-log "INFO" "copying ASAR auxiliary data"
  for aux in $( cat ${joborder} | sort -u | grep "^aux=" | cut -d "=" -f 2- )
  do
    enclosure=$( opensearch-client ${aux} enclosure )
    [ -z "${enclosure}" ] && ${ERR_ENVISAT_AUX}
    ciop-copy -O ${TMPDIR}/aux/ENVI/ASA_INS ${enclosure}
    [ "$?" != "0" ] && return ${ERR_ENVISAT_AUX} 
  done
	
  # create the list of ASA_INS_AX
  ls ${TMPDIR}/aux/ENVI/ASA_INS/ASA_INS* | sed 's#.*/\(.*\)#\1#g' > ${TMPDIR}/aux/ENVI/ASA_INS/list
  [ ! -e "${TMPDIR}/aux/ENVI/ASA_INS/list" ] && return ${ERR_ENVISAT_AUX} 
  
}

function prep_data_ENVISAT() {
  
  local joborder=$1
  
  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   
  
  master_or="$( opensearch-client ${master_ref} enclosure )" 
  slave_or="$( opensearch-client  ${slave_ref} enclosure )"
   
  master_identifier=$( opensearch-client ${master_ref} identifier )
  slave_identifier=$( opensearch-client ${slave_ref} identifier )
  
  master=$( ciop-copy -O ${TMPDIR}/runtime/raw ${master_or} )
  slave=$( ciop-copy -O ${TMPDIR}/runtime/raw ${slave_or} )
   
  [ -z "${master_or}" ] || \
    [ -z "${slave_or}" ] || \
    [ -z "${master_identifier}" ] || \
    [ -z "${slave_identifier}" ] || \
    [ -z "${master}" ] || \
    [ -z "${slave}" ] && return ${ERR_ENVISAT_PREP}  
   
  cd ${TMPDIR}/runtime/raw
 
  ln -s ${master} ${TMPDIR}/runtime/raw/master.baq
  ln -s ${slave} ${TMPDIR}/runtime/raw/slave.baq

  [ ! -e "${${TMPDIR}/runtime/raw/master.baq}" ] && return ${ERR_ENVISAT_PREP} 
  [ ! -e "${${TMPDIR}/runtime/raw/slave.baq}" ] && return ${ERR_ENVISAT_PREP} 

}

function process_ENVISAT() {

  local joborder=$1

  series=$( get_series ${joborder} )
  
  #master_ref=$( get_value ${joborder} "master" )   
  #slave_ref=$( get_value ${joborder} "slave" )
  
  #master_date=$( opensearch-client "${master_ref}" startdate | cut -c 1-10 | tr -d "-" )
  #slave_date=$( opensearch-client "${slave_ref}" startdate | cut -c 1-10 | tr -d "-" )

  ciop-log "INFO" "Process p2p ${series}"
  cd ${TMPDIR}/runtime
  
  csh -x ${_CIOP_APPLICATION_PATH}/gmtsar/libexec/run_envi.csh & #> $TMPDIR/runtime/${series}_${master_date}_${slave_date}.log &
  wait ${!}	

  # TODO add a check on produced files

}





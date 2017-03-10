function env_ENVI() {

  ciop-log "INFO" "Extending environment for ENVISAT ASAR"
  
  mkdir -p ${TMPDIR}/aux/ENVI/ASA_INS
  mkdir -p ${TMPDIR}/aux/ENVI/Doris

  export ORBITS=${TMPDIR}/aux  

}


function get_aux_ENVI() {
  
  local joborder=$1

  for doris in $( cat ${joborder} | sort -u | grep "^.or=" | cut -d "=" -f 2- )
  do
    enclosure=$( opensearch-client ${doris} enclosure )
    ciop-copy -O ${TMPDIR}/aux/ENVI/Doris ${enclosure}
    [ "$?" != "0" ] && exit ${ERR_DOR}
  done

  ciop-log "INFO" "copying ASAR auxiliary data"
  for aux in $( cat ${joborder} | sort -u | grep "^aux=" | cut -d "=" -f 2- )
  do
    enclosure=$( opensearch-client ${aux} enclosure )
    ciop-copy -O ${TMPDIR}/aux/ENVI/ASA_INS ${enclosure}
    [ "$?" != "0" ] && exit ${ERR_AUX} 
  done
	
  # create the list of ASA_INS_AX
  ls ${TMPDIR}/aux/ENVI/ASA_INS/ASA_INS* | sed 's#.*/\(.*\)#\1#g' > ${TMPDIR}/aux/ENVI/ASA_INS/list

}

function prep_data_ENVI() {
  
  local joborder=$1
  
  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   
  
  master_or="$( opensearch-client ${master_ref} enclosure )" 
  slave_or="$( opensearch-client  ${slave_ref} enclosure )"
  
  master_identifier=$( opensearch-client ${master_ref} identifier )
  slave_identifier=$( opensearch-client ${slave_ref} identifier )
  
  master=$( ciop-copy -O ${TMPDIR}/runtime/raw ${master_or} )
  slave=$( ciop-copy -O ${TMPDIR}/runtime/raw ${slave_or} )
   
  cd ${TMPDIR}/runtime/raw
 
  ln -s ${master} ${TMPDIR}/runtime/raw/master.baq
  ln -s ${slave} ${TMPDIR}/runtime/raw/slave.baq

}

function process_ENVI() {

  local joborder=$1

  series=$( get_series ${joborder} )
  
  #master_ref=$( get_value ${joborder} "master" )   
  #slave_ref=$( get_value ${joborder} "slave" )
  
  #master_date=$( opensearch-client "${master_ref}" startdate | cut -c 1-10 | tr -d "-" )
  #slave_date=$( opensearch-client "${slave_ref}" startdate | cut -c 1-10 | tr -d "-" )

  ciop-log "INFO" "Process p2p ${series}"
  cd ${TMPDIR}/runtime
  
  csh ${_CIOP_APPLICATION_PATH}/gmtsar/libexec/run_ENVI.csh & #> $TMPDIR/runtime/${series}_${master_date}_${slave_date}.log &
  wait ${!}	

}





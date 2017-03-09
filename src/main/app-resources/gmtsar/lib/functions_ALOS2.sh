
function env_ALOS2() {
  ciop-log "INFO" "Nothing to do in env_ALOS2"
}

function get_aux_ALOS2() {
  ciop-log "INFO" "Nothing to do in get_aux_ALOS2"
}

function prep_data_ALOS2() {
  
  local joborder=$1
  
  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   
  
  master_identifier=$( opensearch-client ${master_ref} identifier )
  slave_identifier=$( opensearch-client ${slave_ref} identifier )
  
  master_or="$( opensearch-client -p do=va4 ${master_ref} enclosure )" 
  slave_or="$( opensearch-client -p do=va4 ${slave_ref} enclosure )"
     
  master="$( ciop-copy -O ${TMPDIR}/runtime/raw ${master_or} )"
  slave="$( ciop-copy -O ${TMPDIR}/runtime/raw ${slave_or} )"
 
}

function process_ALOS2() {

  local joborder=$1

  series=$( get_series ${joborder} )

  ciop-log "INFO" "Process p2p ${series}"
  
  csh ${_CIOP_APPLICATION_PATH}/gmtsar/libexec/run_${series}.csh & #> $TMPDIR/runtime/${result}_envi.log &
  wait ${!}

}





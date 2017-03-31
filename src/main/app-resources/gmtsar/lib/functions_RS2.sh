
function env_RS2() {
  ciop-log "INFO" "Nothing to do in env_RADARSAT-2"
}

function get_aux_RS2() {
  ciop-log "INFO" "Nothing to do in get_aux_RADARSAT-2"
}

function make_slc_RS2() {

  local sar_ref=$1
  local sar_date
  local identifier

  sar_date=$( opensearch-client "${sar_ref}" startdate | cut -c 1-10 | tr -d "-" )
  identifier=$( opensearch-client "${sar_ref}" identifier )

  cd ${TMPDIR}/runtime/raw
  make_slc_rs2 ${identifier}/product.xml ${identifier}/imagery_HH.tif RS2${sar_date}  

  tree 
  extend_orbit RS2${sar_date}.LED tmp 3.
  mv tmp RS2${sar_date}.LED
  
}


function prep_data_RS2() {
  
  local joborder=$1
  
  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   
 
  # resolve the online resources 
  master_or="$( opensearch-client ${master_ref} enclosure )" 
  slave_or="$( opensearch-client ${slave_ref} enclosure )"
  
  # stage-in the data
  master=$( ciop-copy -U -O ${TMPDIR}/runtime/raw ${master_or} )
  slave=$( ciop-copy -U -O ${TMPDIR}/runtime/raw ${slave_or} )

  # extract data
  tar xvzf ${master}
  tar xvzf ${slave}

  # pre-process master
  make_slc_RS2 ${master_ref}
  
  # pre-process slave
  make_slc_RS2 ${slave_ref}
  
}

function process_RS2() {

  local joborder=$1

  series=$( get_series ${joborder} )

  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   

  master_date=$( opensearch-client "${master_ref}" startdate | cut -c 1-10 | tr -d "-" )
  slave_date=$( opensearch-client "${slave_ref}" startdate | cut -c 1-10 | tr -d "-" )
  
  ciop-log "INFO" "Process p2p ${series}"
  
  cd ${TMPDIR}/runtime
  
  csh ${_CIOP_APPLICATION_PATH}/gmtsar/libexec/run_rs2.csh RS2${master_date} RS2${slave_date}  & #> $TMPDIR/runtime/${series}_${master_date}_${slave_date}.log &
  wait ${!}

}





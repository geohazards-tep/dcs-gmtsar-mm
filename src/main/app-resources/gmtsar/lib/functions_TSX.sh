
function env_TSX() {
  ciop-log "INFO" "Nothing to do in env_TSX"
}

function get_aux_TSX() {
  ciop-log "INFO" "Nothing to do in get_aux_TSX"
}

function make_slc_TSX() {

  local sar_date=$1
  
  cd ${TMPDIR}/runtime/raw
  cd $( dirname $( find . -name "*${sar_date}*.xml" ))
  make_slc_tsx $( find . -name "*${sar_date}*.xml" ) $( find IMAGEDATA -name "*.cos" ) TSX${sar_date}
  mv TSX${sar_date}* ${TMPDIR}/runtime/raw

  cd ${TMPDIR}/runtime/raw
  extend_orbit TSX{sar_date}.LED tmp 3.
  mv tmp TSX{sar_date}.LED
  
}


function prep_data_TSX() {
  
  local joborder=$1
  
  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   
  
  master_identifier=$( opensearch-client ${master_ref} identifier )
  slave_identifier=$( opensearch-client ${slave_ref} identifier )
  
  master_or="$( opensearch-client -p do=va4 ${master_ref} enclosure )" 
  slave_or="$( opensearch-client -p do=va4 ${slave_ref} enclosure )"
  
  master=$( ciop-copy -O ${TMPDIR}/runtime/raw ${master_or} )
  slave=$( ciop-copy -O ${TMPDIR}/runtime/raw ${slave_or} )

  # pre-process master
  master_date=$( opensearch-client "${master_ref}" startdate | cut -c 1-10 | tr -d "-" ) 
  
  make_slc_TSX ${master_date}
  
  # pre-process slave
  slave_date=$( opensearch-client "${slave_ref}" startdate | cut -c 1-10 | tr -d "-" ) 
  
  make_slc_TSX ${slave_date}
  
}

function process_TSX() {

  local joborder=$1

  series=$( get_series ${joborder} )

  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   

  master_date=$( opensearch-client "${master_ref}" startdate | cut -c 1-10 | tr -d "-" )
  slave_date=$( opensearch-client "${slave_ref}" startdate | cut -c 1-10 | tr -d "-" )
  
  ciop-log "INFO" "Process p2p ${series}"
  
  cd ${TMPDIR}/runtime
  
  csh ${_CIOP_APPLICATION_PATH}/gmtsar/libexec/run_${series}.csh TSX${master_date} TSX${slave_date}  & #> $TMPDIR/runtime/${series}_${master_date}_${slave_date}.log &
  wait ${!}

}






function env_RADARSAT-2() {
  ciop-log "INFO" "Nothing to do in env_RADARSAT-2"
}

function get_aux_TSX() {
  ciop-log "INFO" "Nothing to do in get_aux_RADARSAT-2"
}

function make_slc_RADARSAT-2() {

  local sar_ref=$1
  local sar_date

  sar_date=$( opensearch-client "${sar_ref}" startdate | cut -c 1-10 | tr -d "-" )

  cd ${TMPDIR}/runtime/raw

  # GMT5SAR code
  #cd $( dirname $( find . -name "*${sar_date}*.xml" ))
  #make_slc_tsx $( find . -name "*${sar_date}*.xml" ) $( find IMAGEDATA -name "*.cos" ) TSX${sar_date}
  #mv TSX${sar_date}* ${TMPDIR}/runtime/raw
  #
  #cd ${TMPDIR}/runtime/raw
  ##make_slc_rs2 -idims_op_oc_dfd2_370205611_1/TSX-1.SAR.L1B/TSX1_SAR__SSC______SM_S_SRA_20120615T162057_20120615T162105/TSX1_SAR__SSC______SM_S_SRA_20120615T162057_20120615T162105.xml -pTSX20120615

  tree 
  extend_orbit TSX${sar_date}.LED tmp 3.
  mv tmp TSX${sar_date}.LED
  
}


function prep_data_RADARSAT-2() {
  
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
  make_slc_TSX ${master_ref}
  
  # pre-process slave
  make_slc_TSX ${slave_ref}
  
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
  
  csh ${_CIOP_APPLICATION_PATH}/gmtsar/libexec/run_rs2.csh RS2${master_date} RS2${slave_date}  & #> $TMPDIR/runtime/${series}_${master_date}_${slave_date}.log &
  wait ${!}

}





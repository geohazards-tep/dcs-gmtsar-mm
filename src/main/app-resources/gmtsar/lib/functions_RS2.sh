
function env_RS2() {
  
  ciop-log "INFO" "Updating GMTSAR configuration file"

  local threshold_snaphu=$( ciop-getparam "threshold_snaphu" )

  rs2_conf=${TMPDIR}/runtime/config.rs2.txt

cat <<EOF > ${rs2_conf}
proc_stage = 1
num_patches =
earth_radius =
near_range =
fd1 =
topo_phase = 1
shift_topo = 0
switch_master = 0
filter_wavelength = 80
dec_factor = 1
threshold_snaphu = ${threshold_snaphu}
region_cut =
switch_land = 1
defomax = 2 
threshold_geocode = .18
EOF
 
  ciop-publish -m ${rs2_conf}

}

function get_aux_RS2() {
  ciop-log "INFO" "Nothing to do in get_aux_RADARSAT-2"
}

function prep_data_RS2() {
  
  local joborder=$1

  polarization="$( ciop-getparam pol )"
 
  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   
 
  # resolve the online resources 
  master_or="$( opensearch-client ${master_ref} enclosure )" 
  slave_or="$( opensearch-client ${slave_ref} enclosure )"
  
  # stage-in the data
  master=$( ciop-copy -O ${TMPDIR}/runtime/raw ${master_or} )
  slave=$( ciop-copy -O ${TMPDIR}/runtime/raw ${slave_or} )

  master_xml=${master}/$( basename ${master} )/product.xml
  slave_xml=${slave}/$( basename ${slave} )/product.xml

  master_img=${master}/$( basename ${master} )/imagery_${polarization}.tif
  slave_img=${slave}/$( basename ${slave} )/imagery_${polarization}.tif

  master_gmtsar=RS2$( basename ${master} | cut -d _ -f 6)
  slave_gmtsar=RS2$( basename ${slave} | cut -d _ -f 6)


  cd ${TMPDIR}/runtime/raw

  # pre-process master
  make_slc_rs2 ${master_xml} ${master_img} ${master_gmtsar} 1>&2 
  
  # pre-process slave
  make_slc_rs2 ${slave_xml} ${slave_img} ${slave_gmtsar} 1>&2 

  tree . 

  cp ${master_gmtsar}.LED ${master_gmtsar}.LED_orig 
  extend_orbit ${master_gmtsar}.LED tmp 10. 1>&2 

  ciop-log "DEBUG" "exit code $? "
  mv tmp ${master_gmtsar}.LED

  cp ${slave_gmtsar}.LED ${slave_gmtsar}.LED_orig
  extend_orbit ${slave_gmtsar}.LED tmp 10. 1>&2 
  ciop-log "DEBUG" "exit code $? "
  mv tmp ${slave_gmtsar}.LED 

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

  p2p_RS2_SLC.csh RS2${master_date} RS2${slave_date} ${TMPDIR}/runtime/config.rs2.txt #&> ${TMPDIR}/p2p_RS2.log
  [ $? -ne 0 ] && return ${ERR_PROCESS}
  touch ${TMPDIR}/p2p_RS2.log
  ciop-log "INFO" "GMT5SAR p2p_ENVI log publication" 
  ciop-publish -m ${TMPDIR}/p2p_RS2.log

  for result in $( find ${TMPDIR}/runtime/intf/*/* )
  do
    ciop-log "DEBUG" "result: ${result} - ${TMPDIR}/runtime/intf/$( basename ${result} )"
    mv ${result} ${TMPDIR}/runtime/intf/$( basename ${result} )
  done

}





ERR_ENVISAT_DOR=80
ERR_ENVISAT_AUX=81
ERR_ENVISAT_PREP=82

function env_ENVISAT() {

 ciop-log "INFO" "Updating GMTSAR configuration file"

  local threshold_snaphu=$( ciop-getparam "threshold_snaphu" )

  envi_conf=${TMPDIR}/runtime/config.envi.txt

cat <<EOF > ${envi_conf}
proc_stage = 1
num_patches =
earth_radius =
near_range =
fd1 =
topo_phase = 1
shift_topo = 0
switch_master = 0
filter_wavelength = 300
dec_factor = 2
threshold_snaphu = ${threshold_snaphu}
region_cut =
switch_land = 1
defomax = 0
threshold_geocode = .10
EOF
 
  ciop-publish -m ${envi_conf}


  ciop-log "INFO" "Extending environment for ENVISAT ASAR"
 
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
  [ ! -e "${TMPDIR}/aux/ENVI/ASA_INS/list" ] && return ${ERR_ENVISAT_AUX} || return 0 
 
  ciop-log "DEBUG" "$( cat ${TMPDIR}/aux/ENVI/ASA_INS/list )"
   
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

}

function process_ENVISAT() {

  local joborder=$1

  series=$( get_series ${joborder} )
  
  ciop-log "INFO" "Process p2p ${series}"
  cd ${TMPDIR}/runtime
 
  p2p_ENVI.csh master slave ${TMPDIR}/runtime/config.envi.txt &> ${TMPDIR}/p2p_ENVISAT.log
  [ $? -ne 0 ] && return ${ERR_PROCESS}
  
  ciop-log "INFO" "GMT5SAR p2p_ENVI log publication" 
  ciop-publish -m ${TMPDIR}/p2p_ENVISAT.log

  for result in $( find ${TMPDIR}/runtime/intf/*/* )
  do  
    ciop-log "DEBUG" "result: ${result} - ${TMPDIR}/runtime/intf/$( basename ${result} )"
    mv ${result} ${TMPDIR}/runtime/intf/$( basename ${result} )
  done

}





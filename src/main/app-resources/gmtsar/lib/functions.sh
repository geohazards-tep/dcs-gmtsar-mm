
SUCCESS=0

function cleanExit () {

  local retval=$?
  local msg=""
  
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    *) msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
  
}

function get_value() {

  local joborder=$1
  local key=$2
  
  value=$( cat ${joborder} | grep "^${key}=" | cut -d "=" -f 2- )

  echo ${key}

}

function get_series() {

  local joborder=$1
  local series
  
  series=$( get_value ${joborder} "series" )
  
  [ -z "${series}" ] && return ${ERR_SERIES}
  
  ciop-log "INFO" "Working with ${series} data"
 
  echo ${series}

}

function gmtsar_env() {

  local joborder=$1
 
  mkdir -p ${TMPDIR} \
    ${TMPDIR}/runtime/raw \
    ${TMPDIR}/runtime/topo \
    ${TMPDIR}/runtime/log \
    ${TMPDIR}/runtime/orig \
    ${TMPDIR}/runtime/intf &> /dev/null

  series=$( get_series ${joborder} )

  eval env_${series} ${joborder} || return ${ERR_ENV}
  
}

function get_aux() {

  series=$( get_value ${joborder} "series" )

  eval get_aux_${series} ${joborder} || return ${ERR_GET_AUX}

}

function prep_data() {

  local joborder=$1
  local master_ref
  local slave_ref
  local series
  
  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   
  
  for ref in ${master_ref} ${slave_ref}
  do 
    ciop-log "INFO" "Retrieve ${ref}"
     
    local_ref=$( ciop-copy -O ${TMPDIR}/runtime/orig ${ref} )  
    
    [ ! -e "${local_ref}" ] && return ${ERR_GET_DATA}
       
  done
  
  series=$( get_series ${joborder} )

  eval prep_data_${series} ${joborder} || return ${ERR_PREP_DATA}

}

function get_dem() {

  cd ${TMPDIR}/runtime/raw
  
  ln -s ../topo/dem.grd .

}

function process() {

  local series
  local joborder=$1

  series=$( get_series ) || return $?

  eval process_${series} || return $?

}

function publish() {

  # publish results and logs
  ciop-log "INFO" "publishing log files"
  ciop-publish -m ${TMPDIR}/runtime/${result}_${flag}.log
	
  ciop-log "INFO" "result packaging"
  mydir=$( ls ${TMPDIR}/runtime/intf/ | sed 's#.*/\(.*\)#\1#g' )

  ciop-log "DEBUG" "outputfolder is: ${TMPDIR}/runtime/intf + ${mydir}"

  cd ${TMPDIR}/runtime/intf/${mydir}

  #creates the tiff files
  for mygrd in $( ls *ll.grd );
  do
    gdal_translate ${mygrd} $( echo ${mygrd} | sed 's#\.grd#.tiff#g' )
  done
	
  for mygrd in $( ls *.grd )
  do 
    gzip -9 ${mygrd}
  done
        
  cd ${TMPDIR}/runtime/intf

  ciop-log "INFO" "publishing results"
  for myext in png ps gz tiff
  do
    ciop-publish -b ${TMPDIR}/runtime/intf -m ${mydir}/*.${myext}
  done

}

function main() {
  
  source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_S1.sh
  source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_TSX.sh
  source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_ALOS2.sh
  source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_ENVISAT.sh
  
  local joborder_ref=$1
  
  ciop-log "INFO" "processing input: ${joborder_ref}"
  
  export TMPDIR=/tmp/$( uuidgen )
  mkdir -p ${TMPDIR}
  
  cd ${TMPDIR}
  
  joborder=$( ciop-copy ${joborder_ref} )

  gmtsar_env ${joborder}

  get_dem

  get_aux ${joborder}

  prep_data ${joborder}

  process ${joborder}
  
  publish

}

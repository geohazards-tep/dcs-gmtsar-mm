
SUCCESS=0
ERR_DEM=30

function cleanExit () {

  local retval=$?
  local msg=""
  
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    ${ERR_DEM}) msg="No DEM";;
    *) msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
  
}

function get_value() {

  local joborder=$1
  local key=$2
  
  value=$( cat ${joborder} | grep "^${key}=" | cut -d "=" -f 2- )

  echo ${value}

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

  export OS=$( uname -p )
  export GMTHOME=/usr
  export NETCDFHOME=/usr
  export GMTSARHOME=/usr/local/GMTSAR
  export GMTSAR=${GMTSARHOME}/gmtsar

  export PATH=${GMTSAR}/bin:${GMTSAR}/csh:${GMTSARHOME}/preproc/bin:${PATH}

  eval env_${series} ${joborder} || return ${ERR_ENV}
  
}

function get_aux() {

  local joborder=$1  

  series=$( get_value ${joborder} "series" )

  eval get_aux_${series} ${joborder} || return ${ERR_GET_AUX}

}

function prep_data() {

  local joborder=$1
  local series
  
  series=$( get_series ${joborder} )

  eval prep_data_${series} ${joborder} || return ${ERR_PREP_DATA}

}

function get_dem() {

  local dem_response=$1
  local wf_id
  local job_id
  local dem_url

  wf_id=$( echo ${dem_response} | cut -d "/" -f 7 )
  job_id=$( echo ${dem_response} | cut -d "/" -f 8 )

  # retrieve the DEM
  dem_url="$( ciop-browseresults -r ${wf_id} -j ${job_id} | tr -d '\n\r' )" 

  ciop-log "DEBUG" "dem url is ${dem_url}"

  # extract the result URL
  curl -L -o ${TMPDIR}/runtime/topo/dem.tgz "${dem_url}" 2> /dev/null
  [ ! -e ${TMPDIR}/runtime/topo/dem.tgz ] && return ${ERR_NODEM}

  tar xzf ${TMPDIR}/runtime/topo/dem.tgz -C ${TMPDIR}/runtime/topo

  rm -f ${TMPDIR}/runtime/topo/dem.tgz
 
  [ ! -e ${TMPDIR}/runtime/topo/dem.grd ] && return ${ERR_DEM}

  cd ${TMPDIR}/runtime/raw
  
  ln -s ../topo/dem.grd .

}

function process() {

  local series
  local joborder=$1

  series=$( get_series ${joborder} ) || return $?

  eval process_${series} ${joborder} || return $?

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

  set -x
  
  source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_S1.sh
  source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_TSX.sh
  source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_ALOS2.sh
  source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_ENVISAT.sh
  
  local input
  local joborder_ref
  local dem_response

  export TMPDIR=/tmp/$( uuidgen )
  mkdir -p ${TMPDIR}

  cd ${TMPDIR}

  input="$( cat )"
  joborder_ref="$( echo ${input} | tr " " "\n" | grep joborder )"
  dem_response="$( echo ${input} | tr " " "\n" | grep response )"


  ciop-log "INFO" "processing input: ${joborder_ref}"
 
  joborder=$( ciop-copy ${joborder_ref} )

  gmtsar_env ${joborder}

  get_dem ${dem_response} || return $?

  get_aux ${joborder}

  prep_data ${joborder}

  process ${joborder}
  
  publish

}

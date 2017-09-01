set -x

SUCCESS=0
ERR_ENV=10
ERR_DEM=20
ERR_SERIES=30
ERR_GETAUX=40
ERR_PREP_DATA=50
ERR_JOBORDER=60
ERR_DEMRESPONSE=70
ERR_PROCESS=80
ERR_CONF=90
ERR_PUBLISH=95

source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_S1.sh
source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_TSX.sh
source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_ALOS2.sh
source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_ENVISAT.sh
source ${_CIOP_APPLICATION_PATH}/gmtsar/lib/functions_RS2.sh

function cleanExit () {

  local retval=$?
  local msg=""
  
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    ${ERR_DEM}) msg="No DEM";;
    ${ERR_ENV}) msg="Error setting environment";;
    ${ERR_SERIES}) msg="Error getting series";;
    ${ERR_GETAUX}) msg="Error getting auxiliary files";;
    ${ERR_PREP_DATA}) msg="Error in pre-processing";;
    ${ERR_JOBORDER}) msg="Cannot find Job order ";; 
    ${ERR_DEMRESPONSE}) msg="Cannot find the DEM response";;
    ${ERR_PROCESS}) msg="Error processing ";;
    ${ERR_CONF}) msg="Cannot find config file";;
    ${ERR_PUBLISH}) msg="Cannot publish results";;    
    *) msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
  
}

trap cleanExit EXIT

function get_value() {

  local joborder=$1
  local key=$2
  
  value=$( cat ${joborder} | grep "^${key}=" | cut -d "=" -f 2- )

  echo ${value}

}

function get_series() {

  local joborder=$1
  local series
  
  series=$( get_value ${joborder} "series" | tr -d "\n" | tr -d " " )
  
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

  . /etc/profile.d/gmt5sar.sh  
  
  export GMTSAR=/usr/local/GMT5SAR
  export PATH=${GMTSAR}/bin:${PATH}

  # for gdal
  export PATH=/opt/anaconda/bin:$PATH

  eval env_${series} ${joborder} || return ${ERR_ENV}
}

function get_aux() {

  local joborder=$1  

  series=$( get_series ${joborder} )

  eval get_aux_${series} ${joborder} || return ${ERR_GETAUX}
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

  [ -z "${dem_url}" ] && return ${ERR_DEM}

  ciop-log "DEBUG" "dem url is ${dem_url}"

  # extract the result URL
  curl -L -o ${TMPDIR}/runtime/topo/dem.tgz "${dem_url}" 2> /dev/null
  [ ! -e ${TMPDIR}/runtime/topo/dem.tgz ] && return ${ERR_DEM}

  tar xzf ${TMPDIR}/runtime/topo/dem.tgz -C ${TMPDIR}/runtime/topo

  rm -f ${TMPDIR}/runtime/topo/dem.tgz
 
  [ ! -e ${TMPDIR}/runtime/topo/dem.grd ] && return ${ERR_DEM}

  cd ${TMPDIR}/runtime/raw
  
  ln -s ../topo/dem.grd .

}

function process() {

  local series
  local joborder=$1

  series=$( get_series ${joborder} )  
  
  eval process_${series} ${joborder} || return $?

}

function publish() {

  # publish results 
  #for path in $(find ${TMPDIR}/runtime/ -name "F*")
  #do
#  	ciop-log "INFO" "result packaging ${path}"
#	mydir=$( ls ${path}/intf/ | sed 's#.*/\(.*\)#\1#g' )
#
#	ciop-log "DEBUG" "outputfolder is: ${mydir}"

#	cd ${path}/intf/${mydir}

        cd ${TMPDIR}/runtime/intf

	#creates the tiff files
	for mygrd in $( ls *ll.grd );
	do
	  mytiff=$( echo ${mygrd} | sed 's#\.grd#.tiff#g' )
          gdal_translate ${mygrd} $( echo ${mygrd} | sed 's#\.grd#.tiff#g' )
          listgeo -tfw ${mytiff}
          mv $( echo ${mygrd} | sed 's#\.grd#.tfw#g' ) $( echo ${mygrd} | sed 's#\.grd#.pngw#g' )
	done
	
	for mygrd in $( ls *.grd )
	do 
	   gzip -9 ${mygrd}
	done
        
	#cd ${path}/intf/${mydir}       

	ciop-log "INFO" "publishing results"
	for myext in png ps gz tiff pngw
	do
	   ciop-publish -b ${TMPDIR}/runtime/intf -m *.${myext}  # ${path}/intf/${mydir} -m *.${myext}
	done
#  done
}

function main() {

  local input
  local joborder_ref
  local dem_response

  cd ${TMPDIR}

  input="$( cat )"
  joborder_ref="$( echo ${input} | tr " " "\n" | grep joborder )"
  dem_response="$( echo ${input} | tr " " "\n" | grep response )"

  [ -z {"${joborder_ref}" ] && return ${ERR_JOBORDER}
  [ -z {"${dem_response}" ] && return ${ERR_DEMRESPONSE} 
    
  ciop-log "INFO" "processing input: ${joborder_ref}"
 
  joborder=$( ciop-copy ${joborder_ref} )

  [ ! -e "${joborder}" ] && return ${ERR_JOBORDER}

  gmtsar_env ${joborder} || return ${ERR_ENV}

  get_dem ${dem_response} || return ${ERR_DEM}

  get_aux ${joborder} 

  res=$?

  ciop-log "INFO" "get_aux ended with ${res}"

  prep_data ${joborder} || return ${ERR_PREP_DATA}

  process ${joborder} || return ${ERR_PROCESS}
  
  publish #|| return ${ERR_PUBLISH}

}

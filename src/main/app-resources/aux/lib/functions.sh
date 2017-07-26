# define the exit codes

set -x

SUCCESS=0
ERR_NOMASTER=20
ERR_NOSTARTDATE=30
ERR_NOENDDATE=40
ERR_NOAUXREF=50
ERR_VOR=60
ERR_SAR_PLATFORM=70
ERR_ASAR_AUX=80
ERR_S1A_AUX=90
ERR_SBA_AUX=100
ERR_IDENTIFIER=110

# add a trap to exit gracefully
function cleanExit () {

   local retval=$?
   local msg=""
   case "$retval" in
     ${SUCCESS})        msg="Processing successfully concluded";;
     ${ERR_NOMASTER})   msg="Master reference not provided";;
     ${ERR_NOSTARTDATE})  msg="Could not retrieve product start date";;
     ${ERR_NOENDDATE})    msg="Could not retrieve product end date";;
     ${ERR_NOAUXREF})  msg="Error getting a reference to auxiliary data";;
     ${ERR_ASAR_AUX})  msg="Error getting a reference to ASAR auxiliary data";;
     ${ERR_VOR})  	msg="Error getting a reference to ASAR orbital data data";;
     ${ERR_S1A_AUX})  	msg="Error getting a reference to Sentinel-1A orbital data data";;
     ${ERR_S1B_AUX})  	msg="Error getting a reference to Sentinel-1B orbital data data";;
     ${ERR_SAR_PLATFORM})   msg="Could not identify platform";;
     ${ERR_IDENTIFIER})	msg="Input provided is not in the catalogue";;
     *)               msg="Unknown error";;
   esac
   [ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
   exit $retval
}
trap cleanExit EXIT

function getAUXref() {

  local atom=$1
  local osd=$2
  local series=$3 
 
  startdate=$( opensearch-client ${atom} startdate | tr -d "Z")
  [ -z "${startdate}" ] && return ${ERR_NOSTARTDATE}
  
  stopdate=$( opensearch-client ${atom} enddate | tr -d "Z")
  [ -z "${stopdate}" ] && return ${ERR_NOENDDATE}
  
  ref="$( opensearch-client -p "pi=${series}" -p "time:start=${startdate}" -p "time:end=${stopdate}" ${osd} )" 
  [ -z "${ref}" ] && return ${ERR_AUXREF}
  
  echo ${ref}

}

function getASARAuxOrbList() {

  local sar=$1
  local osd="https://catalog.terradue.com/envisat/search"  

  for aux in ASA_CON_AX ASA_INS_AX ASA_XCA_AX ASA_XCH_AX
  do
    ciop-log "INFO" "Getting a catalogue reference to ${aux}"
    
    ref=$( getAUXref ${sar} ${osd} ${aux} )    
    [ -z "${ref}" ] && return ${ERR_AUXREF}

    for url in ${ref}
    do
      ciop-log "INFO" "the url is ${url}"
       
      #pass the aux reference to the next node
      [ "${url}" != "" ] && echo "aux=${url}"  
    done
    
  done
  
  # DOR_VOR_AX
  ciop-log "INFO" "Getting a reference to DOR_VOR_AX"
  ref=$( getAUXref ${sar} ${osd} DOR_VOR_AX )
  [ -z "${ref}" ] && return ${ERR_VOR} || echo "orb=${ref}"    

}

function getS1AuxOrbList() {

  local sar=$1
  local platform=$2
  local keyword=$3
  local osd="https://catalog.terradue.com/sentinel1-aux/search"
  local refs

  # Precise orbit data - Sentinel-1
  ciop-log "INFO" "Getting a reference to Sentinel ${platform} precise orbit data"

  startdate=$( opensearch-client ${sar} startdate | tr -d "Z")
  [ -z "${startdate}" ] && return ${ERR_NOSTARTDATE}

  stopdate=$( opensearch-client ${sar} enddate | tr -d "Z")
  [ -z "${stopdate}" ] && return ${ERR_NOENDDATE}

  refs="$( opensearch-client -p "psn=${platform}" -p "time:start=${startdate}" -p "time:end=${stopdate}" ${osd} enclosure)"
  [ -z "${refs}" ] && return ${ERR_AUXREF}

  for ref in $(echo ${refs} )
#| grep "POEORB")
  do 
	echo -e "${keyword}=${ref}"
  done

}

function getAuxOrbList() {

  # generic function to retrieve aux data 
  
  local sar=$1
  local keyword=$2
  local platform
  local identifier

  platform=$( opensearch-client -m EOP ${sar} platform )

  [ -z "${platform}" ] && {
    # handle missing metadata
    identifier=$( opensearch-client -m EOP ${sar} identifier )
    [ -z "${identifier}" ] && return ${ERR_SAR_PLATFORM}
  
    # check for TSX
    [ "$( echo ${identifier} | cut -c 1-3 )" == "TSX" ] && platform="TSX"

  } 
  [ -z "${platform}" ] && return ${ERR_SAR_PLATFORM}
 
set -x
 
  case ${platform} in 
    "ENVISAT")
      aux="$( getASARAuxOrbList ${sar} orb)"
      [ -z "${aux}" ] && return ${ERR_ASAR_AUX}
      ;;
    "S1A")
      aux="$( getS1AuxOrbList ${sar} S1A ${keyword})"
#      [ -z "${aux}" ] && return ${ERR_S1A_AUX}
      ;;
    "S1B")
      aux="$( getS1AuxOrbList ${sar} S1B ${keyword})"
      [ -z "${aux}" ] && return ${ERR_S1B_AUX}
      ;;
    "RADARSAT-2")
      aux=""
      platform="RS2"
    ;;
    *)
      aux=""
      ;;
  esac

  echo "series=${platform}"
  echo ${aux} | tr " " "\n"

}

function check_ref() {
 
  local ref=$1
  local identifier
  
  identifier=$( opensearch-client "${ref}" identifier )
  
  [ -z "${identifier}" ] && return ${ERR_IDENTIFIER} || return 0

}

function main() {

  # Get the master - it's always the same
  local master="$( ciop-getparam Level0_ref )"
  
  [ -z "${master}" ] && return ${ERR_NOMASTER} 

  check_ref ${master} || return $?

  ciop-log "INFO" "master is: ${master}"

  # create the first line of the joborder with the reference
  # to the master product 
  echo "master=${master}" > ${TMPDIR}/joborder

  #getAuxOrbList ${master} master_orb >> ${TMPDIR}/joborder
  echo "series=S1A" >> ${TMPDIR}/joborder
  echo "master_orb=file:///home/fbrito/S1/orig/S1A_OPER_AUX_POEORB_OPOD_20151125T122020_V20151104T225943_20151106T005943.EOF.txt" >> ${TMPDIR}/joborder
  res=$?
  [ ${res} -ne 0 ] && return ${res}
 
  # slave is passed via stdin
  slave="$( cat )" 
  
  check_ref ${slave} || return $?
  
  ciop-log "INFO" "slave is: ${slave}"
  	
  echo "slave=${slave}" >> ${TMPDIR}/joborder

#  getAuxOrbList ${slave} slave_orb >> ${TMPDIR}/joborder
  echo "master_orb=file:///home/fbrito/S1/orig/slave_orb=S1A_OPER_AUX_POEORB_OPOD_20151207T122501_V20151116T225943_20151118T005943.EOF.txt" >> ${TMPDIR}/joborder
  res=$?
  [ ${res} -ne 0 ] && return ${res}
   
  sort -u ${TMPDIR}/joborder > ${TMPDIR}/joborder.tmp
  mv ${TMPDIR}/joborder.tmp ${TMPDIR}/joborder

  # TODO add check on series in joborder

  ciop-publish ${TMPDIR}/joborder  

}

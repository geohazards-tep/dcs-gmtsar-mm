# define the exit codes

set -x


SUCCESS=0
ERR_NOMASTER=20
ERR_NOSTARTDATE=30
ERR_NOENDDATE=40
ERR_NOAUXREF=50

# add a trap to exit gracefully
function cleanExit () {

   local retval=$?
   local msg=""
   case "$retval" in
     $SUCCESS)        msg="Processing successfully concluded";;
     $ERR_NOMASTER)   msg="Master reference not provided";;
     $ERR_NOSTARTDATE)  msg="Could not retrieve ASAR product start date";;
     $ERR_NOENDDATE)    msg="Could not retrieve ASAR product end date";;
     $ERR_NOAUXREF)  msg="Error getting a reference to ASAR auxiliry data";;
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
  local osd="https://catalog.terradue.com/sentinel1-aux/search"
  local refs

  # Precise orbit data - Sentinel-1
  ciop-log "INFO" "Getting a reference to Sentinel ${platform} precise orbit data"

  startdate=$( opensearch-client ${sar} startdate | tr -d "Z")
  [ -z "${startdate}" ] && return ${ERR_NOSTARTDATE}

  stopdate=$( opensearch-client ${sar} enddate | tr -d "Z")
  [ -z "${stopdate}" ] && return ${ERR_NOENDDATE}

  refs="$( opensearch-client -p "psn=${platform}" -p "time:start=${startdate}" -p "time:end=${stopdate}" ${osd} )"
  [ -z "${refs}" ] && return ${ERR_AUXREF}

  for ref in ${refs}
  do 
    echo -e "orb=${ref}"
  done

}

function getAuxOrbList() {

  # generic function to retrieve aux data 
  
  local sar=$1
  local platform

  platform=$( opensearch-client -m EOP ${sar} platform )
  [ -z "${platform}" ] && return ${ERR_SAR_PLATFORM}
  
  case ${platform} in 
    "ENVISAT")
      aux="$( getASARAuxOrbList ${sar} )"
      [ -z "${aux}" ] && return ${ERR_ASAR_AUX}
      ;;
    "S1A")
      aux="$( getS1AuxOrbList ${sar} S1A )"
      [ -z "${aux}" ] && return ${ERR_S1A_AUX}
      ;;
    "S1B")
      aux="$( getS1AuxOrbList ${sar} S1B )"
      [ -z "${aux}" ] && return ${ERR_S1B_AUX}
      ;;
    *)
      aux=""
      ;;
  esac

  echo "series=${platform}"
  echo ${aux} | tr " " "\n"

}


function main() {

  # Get the master - it's always the same
  local master="$( ciop-getparam Level0_ref )"
  
  [ -z "${master}" ] && return $ERR_NOMASTER 

  ciop-log "INFO" "master is: ${master}"

  # create the first line of the joborder with the reference
  # to the ASAR master product 
  echo "master=${master}" > $TMPDIR/joborder

  getAuxOrbList ${master} >> $TMPDIR/joborder
  res=$?
  [ ${res} -ne 0 ] && return ${res}

  cat > ${TMPDIR}/slave
 
  slave=$(cat ${TMPDIR}/slave)
  rm -f ${TMPDIR}/slave
  
  ciop-log "INFO" "slave is: ${slave}"
  
  echo "slave="$slave"" >> $TMPDIR/joborder

  getAuxOrbList ${slave} >> $TMPDIR/joborder
  res=$?
  [ $res -ne 0 ] && return $res
   
  sort -u $TMPDIR/joborder > $TMPDIR/joborder.tmp
  mv $TMPDIR/joborder.tmp $TMPDIR/joborder

  ciop-publish $TMPDIR/joborder  

}

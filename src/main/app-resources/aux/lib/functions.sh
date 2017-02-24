# define the exit codes
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
  local osd=$2  

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
  [ -z "${ref}" ] && return ${ERR_VOR} || echo "vor=${ref}"    

}

function getAuxOrbList() {

  # generic function to retrieve aux data 
  
  local master=$1
  local identifier

  identifier=$( opensearch-client ${master} identifier )
  [ -z "${identifier}" ] && return ${ERR_MASTER_IDENTIFIER}

  
  # get the EOP metadata
  opensearch-client \
    -m EOP \
    -f atom \
    ${master} \
    {} | xmllint --format - > ${TMPDIR}/identifier.eop 

  

  rm -f ${TMPDIR}/identifier.eop
 
  # get the product type to invoke the correct function



}


function main() {

  # get the catalogue access point
  osd="$( ciop-getparam aux_catalogue )"

  # Get the master - it's always the same
  local master="$( ciop-getparam Level0_ref )"
  
  [ -z "$master" ] && return $ERR_NOMASTER 

  ciop-log "INFO" "master is: $master"

  # create the first line of the joborder with the reference
  # to the ASAR master product 
  echo "master="$master"" > $TMPDIR/joborder

  getAuxOrbList $master >> $TMPDIR/joborder
  res=$?
  [ $res -ne 0 ] && return $res

  # loop through all slaves
  i=0
  while read slave 
  do
    ciop-log "INFO" "slave is: $slave"
    cp $TMPDIR/joborder $TMPDIR/joborder_${i}.tmp
    echo "slave="$slave"" >> $TMPDIR/joborder_${i}.tmp

    getAuxOrbList $slave $osd >> $TMPDIR/joborder_${i}.tmp
    res=$?
    [ $res -ne 0 ] && return $res
  
    sort -u $TMPDIR/joborder_${i}.tmp > $TMPDIR/joborder_${i}
    
    ciop-publish $TMPDIR/joborder_${i}  
   
    rm -f $TMPDIR/joborder_${i}.tmp $TMPDIR/joborder_${i}
    i=$((i+1))
  done

}

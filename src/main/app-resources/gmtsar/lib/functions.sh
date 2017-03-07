
# define the exit codes
SUCCESS=0

###############################################################################
# Trap function to exit gracefully
# Globals:
#   SUCCESS
# Arguments:
#   None
# Returns:
#   None
###############################################################################
function cleanExit ()
{
  local retval=$?
  local msg=""
  case "${retval}" in
    ${SUCCESS}) msg="Processing successfully concluded";;
    *) msg="Unknown error";;
  esac

  [ "${retval}" != "0" ] && ciop-log "ERROR" "Error ${retval} - ${msg}, processing aborted" || ciop-log "INFO" "${msg}"
  exit ${retval}
}

function get_data() {

  echo   


}

function get_aux() {

  echo

}

function S1A() {

  S1 $@

}

function S1B() {
 
  S1 $@

}

function S1() {

  echo 

}

function env_S1A() {

  env_S1

}

function env_S1B() {

  env_S1

}

function env_S1() {

  gmtsar_env
  
  mkdir ${TMPDIR}/orig 

}

function gmtsar_env() {

  export TMPDIR=/tmp/$( uuidgen )
  mkdir -p ${TMPDIR} ${TMPDIR}/runtime/raw ${TMPDIR}/runtime/topo ${TMPDIR}/runtime/log ${TMPDIR}/runtime/intf &> /dev/null

}


function process() {

  local series
  local joborder=$1

  series=$( cat ${joborder} | grep series | cut -d "=" -f 2- )

  eval env_${series} 

  eval ${series} || return $?

}

function main() {
  
  local input=$1
  
  # Logs the inputs received from the previous node. Since it is configured
  # as 'aggregator' (see application.xml), it collects the inputs of all the
  # instances of the previous node.
  ciop-log "INFO" "processing input: ${input}"

  get_data ${joborder}

  get_aux ${joborder}

  get_dem 

  process ${joborder}

}

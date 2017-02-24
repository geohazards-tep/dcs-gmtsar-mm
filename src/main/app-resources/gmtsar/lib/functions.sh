#!/bin/bash

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

###############################################################################
# Main function to process an input coming from the previous node
# Globals:
#   None
# Arguments:
#   input reference to process
# Returns:
#   0 on success
###############################################################################
function main() {
  
  local input=$1
  
  # Logs the inputs received from the previous node. Since it is configured
  # as 'aggregator' (see application.xml), it collects the inputs of all the
  # instances of the previous node.
  ciop-log "INFO" "processing input: ${input}"
}
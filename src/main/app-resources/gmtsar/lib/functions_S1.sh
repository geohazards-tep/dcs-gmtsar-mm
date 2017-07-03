function env_S1A() {
  env_S1 $@
}

function env_S1B() {
  env_S1 $@
}

function env_S1() {
  ciop-log "INFO" "Nothing to do in env_S1"
}

function get_aux_S1A() {
  get_aux_S1 $@
}

function get_aux_S1B() {
  get_aux_S1 $@
}

function get_aux_S1() {
  
  local joborder=$1

  cat ${joborder} | grep orb | while read orb
  do 
    orb_ref=$( echo ${orb} | cut -d "=" -f 2- )
    
    ciop-log "INFO" "Retrieve orbital data from ${orb_ref}"
    
    local_ref=$( ciop-copy -O ${TMPDIR}/runtime/raw ${orb_ref} )  
    
    [ ! -e "${local_ref}" ] && return ${ERR_GET_AUX}
    
  done
  
}

function prep_data_S1A() {
  prep_data_S1 $@
}

function prep_data_S1B() {
  prep_data_S1 $@
}

function prep_data_S1() {
  
  local joborder=$1
  
  master_ref=$( get_value ${joborder} "master" )   
  slave_ref=$( get_value ${joborder} "slave" )   
  
  master_or="$( opensearch-client ${master_ref} enclosure )" 
  slave_or="$( opensearch-client  ${slave_ref} enclosure )"
  
  master_identifier=$( opensearch-client ${master_ref} identifier )
  slave_identifier=$( opensearch-client ${slave_ref} identifier )
   
  cd ${TMPDIR}/runtime/raw

  mkdir master_raw
  mkdir slave_raw
 
  ln -s ../orig/${master_identifier}/${master_identifier}.SAFE/annotation/*.xml master_raw
  ln -s ../orig/${master_identifier}/${master_identifier}.SAFE/measurement/*.tiff master_raw
  ln -s ../orig/${slave_identifier}/${slave_identifier}.SAFE/annotation/*.xml slave_raw
  ln -s ../orig/${slave_identifier}/${slave_identifier}.SAFE/measurement/*.tiff slave_raw

  ln -s ../topo/dem.grd .

#TODO
#define: which file numbers and which orbit urls

  for filename in $(ls master_raw) do
    master_prefix="${filename%.*}"
    master_fn="{master_prefix: -3}"
    slave_filname="$(find slave_raw/ -name *${master_fn}.tiff -printf '%f\n')"
    slave_prefix="${slave_filename%.*}"
    csh align_tops.csh \
      ${master_prefix} \
      S1A_OPER_AUX_POEORB_OPOD_20151125T122020_V20151104T225943_20151106T005943.EOF.txt \
      ${slave_prefix} \
      S1A_OPER_AUX_POEORB_OPOD_20151207T122501_V20151116T225943_20151118T005943.EOF.txt \
      dem.grd
  done

  cd ..
  rm -r F1/raw
  mkdir F1
  cd F1
  ln -s ../config.s1a.txt .
  mkdir raw
  cd raw
  ln -s ../../raw/*F1* .
  cd ..
  mkdir topo
  cd topo
  ln -s ../../topo/dem.grd .
  cd ../..
  #
  rm -r F2/raw
  mkdir F2
  cd F2
  ln -s ../config.s1a.txt .
  mkdir raw
  cd raw
  ln -s ../../raw/*F2* .
  cd ..
  mkdir topo
  cd topo
  ln -s ../../topo/dem.grd .
  cd ../..
  #
  rm -r F3/raw
  mkdir F3
  cd F3
  ln -s ../config.s1a.txt .
  mkdir raw
  cd raw
  ln -s ../../raw/*F3* .
  cd ..
  mkdir topo
  cd topo
  ln -s ../../topo/dem.grd .
  #

}

function process_S1A() {
  process_S1 $@
}

function process_S1B() {
  process_S1 $@
}

function process_S1() {

#
#   make all the interferograms
#
  cd F1
  p2p_S1A_TOPS.csh S1A20151105_163133_F1 S1A20151117_163127_F1 config.s1a.txt >& log &
  cd ../F2
  p2p_S1A_TOPS.csh S1A20151105_163134_F2 S1A20151117_163128_F2 config.s1a.txt >& log &
  cd ../F3
  p2p_S1A_TOPS.csh S1A20151105_163135_F3 S1A20151117_163129_F3 config.s1a.txt >& log &

}

function main() {

  local input
  local joborder_ref
  local dem_response

  export TMPDIR=/tmp/$( uuidgen )
  mkdir -p ${TMPDIR}

  cd ${TMPDIR}

  input="$( cat )"
  joborder_ref="$( echo ${input} | tr " " "\n" | grep joborder )"
  dem_response="$( echo ${input} | tr " " "\n" | grep response )"

  [ -z {"${joborder_ref}" ] && return ${ERR_JOBORDER}
  [ -z {"${dem_response}" ] && return ${ERR_DEMRESPONSE} 
    
  ciop-log "INFO" "processing input: ${joborder_ref}"
 
  joborder=$( ciop-copy ${joborder_ref} )

  [ ! -e "${joborder}" ] && return ${ERR_JOBORDER}

  gmtsar_env ${joborder} || return $?

  get_dem ${dem_response} || return $?

  get_aux ${joborder} || return $?

  prep_data ${joborder} || return $?

  process ${joborder} || return $?
  
  publish 

}



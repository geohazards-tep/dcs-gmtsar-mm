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
 
  ln -s ../orig/${master_identifier}/${master_identifier}.SAFE annotation/*.xml .
  ln -s ../orig/${master_identifier}/${master_identifier}.SAFE annotation/*.tiff .
  ln -s ../orig/${slave_identifier}/${slave_identifier}.SAFE annotation/*.xml .
  ln -s ../orig/${slave_identifier}/${slave_identifier}.SAFE annotation/*.tiff .

  ln -s ../topo/dem.grd .

  csh align_tops.csh \
    s1a-iw1-slc-vv-20151105t163133-20151105t163201-008472-00bfa6-004 \
    S1A_OPER_AUX_POEORB_OPOD_20151125T122020_V20151104T225943_20151106T005943.EOF.txt \
    s1a-iw1-slc-vv-20151117t163127-20151117t163155-008647-00c499-004 \
    S1A_OPER_AUX_POEORB_OPOD_20151207T122501_V20151116T225943_20151118T005943.EOF.txt \
    dem.grd

  csh align_tops.csh \
    s1a-iw2-slc-vv-20151105t163134-20151105t163159-008472-00bfa6-005 \
    S1A_OPER_AUX_POEORB_OPOD_20151125T122020_V20151104T225943_20151106T005943.EOF.txt \
    s1a-iw2-slc-vv-20151117t163128-20151117t163154-008647-00c499-005 \
    S1A_OPER_AUX_POEORB_OPOD_20151207T122501_V20151116T225943_20151118T005943.EOF.txt \
    dem.grd

  csh align_tops.csh \
    s1a-iw3-slc-vv-20151105t163135-20151105t163200-008472-00bfa6-006 \
    S1A_OPER_AUX_POEORB_OPOD_20151125T122020_V20151104T225943_20151106T005943.EOF.txt \
    s1a-iw3-slc-vv-20151117t163129-20151117t163155-008647-00c499-006 \
    S1A_OPER_AUX_POEORB_OPOD_20151207T122501_V20151116T225943_20151118T005943.EOF.txt \
    dem.grd

}

function process_S1A() {
  process_S1 $@
}

function process_S1B() {
  process_S1 $@
}

function process_S1() {

  echo 

}





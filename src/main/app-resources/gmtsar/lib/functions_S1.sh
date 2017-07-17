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
  get_aux_S1 $@ master
  get_aux_S1 $@ slave


  res=$?

  ciop-log "INFO" "result of get_auxS1A $res"
}

function get_aux_S1B() {
  get_aux_S1 $@ master
  get_aux_S1 $@ slave
}

function get_aux_S1() {
  
  local joborder=$1
  local keyword=$2
  cat ${joborder} | grep ${keyword}_orb | while read orb
  do 
    orb_ref=$( echo ${orb} | cut -d "=" -f 2- )
    
    ciop-log "INFO" "Retrieve orbital data from ${orb_ref}"
    
    mkdir -p ${TMPDIR}/runtime/raw/${keyword}

    local_ref=$( ciop-copy -O ${TMPDIR}/runtime/raw/${keyword} ${orb_ref} )  
    
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
 
  polarization=$( get_value ${joborder} "polarization" )
  
  cd ${TMPDIR}/runtime/raw

#  mkdir master_raw
#  mkdir slave_raw

#TODO enable download from DA
#  echo ${master_or} | ciop-copy -f -O master_raw -
#  echo ${slave_or} | ciop-copy -f -O slave_raw - 
 
  ln -s /home/fbrito/gmt5sar_inputs/master_raw  

  ln -s /home/fbrito/gmt5sar_inputs/slave_raw  

  ls -l master_raw/

#We need to have all the files in the working dir

  for file in $(find -L master_raw/ -name "*.xml" | grep -v calibration) 
  do
  	ln -s ${file}
  done

  for file in $(find -L slave_raw/ -name "*.xml" | grep -v calibration)
  do
        ln -s ${file} 
  done

  for file in $(find -L master_raw/ -name "*.tiff")
  do
        ln -s ${file}
  done

  for file in $(find -L slave_raw/ -name "*.tiff")
  do
        ln -s ${file}
  done

  tree ./

  ln -s ../topo/dem.grd .
  polarization="$( ciop-getparam pol )"
  master_orb="$(echo $(find ./master -name *.EOF) | tr ' ' '\n' | head -1)"
  slave_orb="$(echo $(find ./slave -name *.EOF) | tr ' ' '\n' | head -1)"
  for filename in $(find -L master_raw/ -name "*${polarization}*.tiff" -printf '%f\n') 
  do
    master_prefix="${filename%.*}"
    master_fn="${master_prefix: -3}"
    slave_filename="$(find -L slave_raw/ -name "*${master_fn}*.tiff" -printf '%f\n')"
    slave_prefix="${slave_filename%.*}"
    ciop-log "INFO" "align_tops.csh ${master_prefix} "${master_orb}" ${slave_prefix} "${slave_orb}" dem.grd "
    align_tops.csh \
      ${master_prefix} \
      ${master_orb} \
      ${slave_prefix} \
      ${slave_orb} \
      dem.grd
    [ $? -ne 0 ] && return ${ERR_PREP_DATA}
  done

  tree ./

  cd ..
  rm -r F1/raw

  cp ${_CIOP_APPLICATION_PATH}/gmtsar/etc/config.s1a.txt .
 
  [ $? -ne 0 ] && return ${ERR_PROCESS}
 
  master_prep_id=$(echo ${master_identifier} | cut -d '_' -f6 | cut -d 'T' -f1)
  slave_prep_id=$(echo ${slave_identifier} | cut -d '_' -f6 | cut -d 'T' -f1)

  mkdir F1
  cd F1
  ln -s ../config.s1a.txt .
  mkdir raw
  cd raw
  cp ../../raw/*${master_prep_id}*F1* .
  cp ../../raw/*${slave_prep_id}*F1* .
  mkdir master
  cd master
  ln -s ../*${master_prep_id}*F1* .
  cd ../
  mkdir slave
  cd slave
  ln -s ../*${slave_prep_id}*F1* .
  cd ../../
  mkdir topo
  cd topo
  ln -s ../../topo/dem.grd .
  cd ../../
  #
  rm -r F2/raw
  mkdir F2
  cd F2
  ln -s ../config.s1a.txt .
  mkdir raw
  cd raw
  cp ../../raw/*${master_prep_id}*F2* .
  cp ../../raw/*${slave_prep_id}*F2* .
  mkdir master
  cd master
  ln -s ../*${master_prep_id}*F2* .
  cd ../
  mkdir slave
  cd slave
  ln -s ../*${slave_prep_id}*F2* .
  cd ../../
  mkdir topo
  cd topo
  ln -s ../../topo/dem.grd .
  cd ../../
  #
  rm -r F3/raw
  mkdir F3
  cd F3
  ln -s ../config.s1a.txt .
  mkdir raw
  cd raw
  cp ../../raw/*${master_prep_id}*F3* .
  cp ../../raw/*${slave_prep_id}*F3* .
  mkdir master
  cd master
  ln -s ../*${master_prep_id}*F3* .
  cd ..
  mkdir slave
  cd slave
  ln -s ../*${slave_prep_id}*F3* .
  cd ../../
  mkdir topo
  cd topo
  ln -s ../../topo/dem.grd .

  cd ../../

  tree ./
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

  cd ${TMPDIR}/runtime
  
#  master_prep_id="$(find ./F1/raw/master/ -printf "%f\n" | grep -v '/' | head -1 | cut -d 'T' -f1)"
#  slave_prep_id="$(find ./F1/raw/slave/ -printf "%f\n" | grep -v '/' | head -1 | cut -d 'T' -f1)"

#  for i in {1..3}
 # do
	for master_file in $(find ./*/raw/master/ -name *.SLC -printf "%f\n")
	do 
  	    filenumber=$(echo ${master_file} | cut -d '_' -f3 | cut -d '.' -f1)
	    slave_file=$(find ./${filenumber}/raw/slave/ -name *.SLC -printf "%f\n")
	    cd ${filenumber}
	    p2p_S1A_TOPS.csh ${master_file%.*} ${slave_file%.*} config.s1a.txt  
   	    [ $? -ne 0 ] && return ${ERR_PROCESS}
            cd ..
	done
  #done
}



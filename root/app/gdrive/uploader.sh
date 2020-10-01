#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
## function source
source /app/functions/functions.sh
#Make sure all the folders we need are created
base_folder_gdrive
downloadpath=/move
MOVE_BASE=${MOVE_BASE:-/}
# Check encryption status
ENCRYPTED=${ENCRYPTED:-false}
if [[ "${ENCRYPTED}" == "false" ]]; then
  if grep -q gcrypt /config/rclone/rclone-docker.conf; then
     ENCRYPTED=true
  fi
fi
test_2=$(ls /config | grep -c xml)
test_1=$(ls /app | grep -c xml)
if [ ${BWLIMITSET} == 'null' ]; then
   if [[ ${test_1} == "1" || ${test_2} == "1" ]]; then
      BWLIMITSET=80
   else
      BWLIMITSET=100
   fi
else
   BWLIMITSET=${BWLIMITSET}
fi
BASICIGNORE="! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '**.inProgress/**'"
DOWNLOADIGNORE="! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**' ! -path '**-vpn/**' ! -path '**_UNPACK_**'"
ADDITIONAL_IGNORES=${ADDITIONAL_IGNORES}
if [ "${ADDITIONAL_IGNORES}" == 'null' ]; then
   ADDITIONAL_IGNORES=""
fi
discord_start_send_gdrive
remove_old_files_start_up
cleanup_start
bc_start_up_test
# Grabs vars from files
if [ -e /config/vars/lastGDSA ]; then
   GDSAAMOUNT=$(cat /config/vars/gdsaAmount)
else
   GDSAAMOUNT=0
fi
##scaled_bandwith
USEDUPLOADSPEED=$(echo $(( ( ${BWLIMITSET} )/10*9 | bc )) | sed -r 's/([^0-9]*([0-9]*)){1}.*/\2/')
if [ ${USEDUPLOADSPEED} -le ${BWLIMITSET} ]; then
    log "calculator for bandwidth working"
else
    log "calculator for bandwidth don't work"
    exit 1
fi
# Run Loop
while true; do
    mapfile -t timestamps < <(eval find /config/vars/gdrive -type f)
    for file in "${timestamps[@]}";
    do
        if [ "$(basename "${file}")" -ge "$(date +%s)" ]; then
            tmpamount=$(echo "${GDSAAMOUNT} - $(cat "${file}")" | bc)
            if [[ "${tmpamount}" =~ ^[0-9]+$ ]]; then
               log "taking $(cat "${file}") from ${GDSAAMOUNT}"
               GDSAAMOUNT=${tmpamount}
            else
               GDSAAMOUNT=0
            fi
            rm -fr "${file}"
        fi
    done
    #Find files to transfer
    IFS=$'\n'
    mapfile -t files < <(eval find ${downloadpath} -cmin +2 -type f ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES})
    if [[ ${#files[@]} -gt 0 ]]; then
        # If files are found loop though and upload
        log "Files found to upload"
        for i in "${files[@]}"; do
            FILEDIR=$(dirname "${i}" | sed "s#${downloadpath}${MOVE_BASE}##g")
            # If file has a lockfile skip
            if [ -e "${i}.lck" ]; then
                log "Lock File found for ${i}"
                continue
            else
                if [ -e "${i}" ]; then
                    # Check if file is still getting bigger
                    FILESIZE1=$(stat -c %s "${i}")
                    sleep 3
                    FILESIZE2=$(stat -c %s "${i}")
                    if [ "$FILESIZE1" -ne "$FILESIZE2" ]; then
                        log "File is still getting bigger ${i}"
                        continue
                    fi
                    # shellcheck disable=SC2010
                    TRANSFERS=$(ls /config/pid/ | egrep trans | wc -l )
                    test1=$(vnstat -i eth0 -tr 2 | awk '$1 == "tx" {print $3}')
                    if [ ${test1} != "MB/s" ]; then
                       UPLOADSPEED=1
                    else
                       UPLOADSPEED=$(vnstat -i eth0 -tr 2 | awk '$1 == "tx" {print $2}' | sed -r 's/([^0-9]*([0-9]*)){1}.*/\2/')
                    fi
                    UPLOADFILE=$(echo $(( ((${BWLIMITSET}-${UPLOADSPEED})) | bc )) | sed -r 's/([^0-9]*([0-9]*)){1}.*/\2/')
                    # shellcheck disable=SC2086
                    # shellcheck disable=SC2086
                    if [[ -e "${i}" && ${UPLOADSPEED} -le ${BWLIMITSET} && ${UPLOADFILE} -gt 15 ]]; then                  
                       log "attacke .....  ${i} will uploaded"                      
                       log "Upload Bandwith is calculated for ${i}"
                       log "Starting upload of ${i}"
                       if [ ${UPLOADFILE} -gt 35 ]; then
                           UPLOADFILE=30
                       else
                           UPLOADFILE=${UPLOADFILE}
                       fi
                       FILEBASE=$(basename "${i}")
                       echo ${UPLOADFILE} >> /config/json/${FILEBASE}.bwlimit
                       # Append filesize to GDSAAMOUNT
                       GDSAAMOUNT=$(echo "${GDSAAMOUNT} + ${FILESIZE2}" | bc)
                       # Set gdrive as crypt or not
                       if [ ${ENCRYPTED} == "true" ]; then
                          GDSA_TO_USE="gcrypt"
                       else
                           GDSA_TO_USE="gdrive"
                       fi
                       # Increase or reset $GDSAUSE?
                       # shellcheck disable=SC2086
                       if [ ${GDSAAMOUNT} -gt "783831531520" ]; then
                          log "${GDSA_TO_USE} has hit 730GB uploads will resume when they can ( ︶︿︶)_╭∩╮" 
                          break
                       fi
                       echo "${FILESIZE2}" > "/config/vars/gdrive/$(echo "$(date +%s) + 86400" | bc)"						   
                       /app/uploader/upload.sh "${i}" "${GDSA_TO_USE}" &
                       PID=$!
                       FILEBASE=$(basename "${i}")
                       # Add transfer to pid directory
                       echo "${PID}" > "/config/pid/${FILEBASE}.trans"
                       log "${GDSA_TO_USE} is now $(echo "${GDSAAMOUNT}/1024/1024/1024" | bc -l)"
                       # Record GDSA transfered in case of crash/reboot
                       echo "gdrive" >/config/vars/lastGDSA
                       echo "${GDSAAMOUNT}" >/config/vars/gdsaAmount
                    else 
                       if [ ${TRANSFERS} -gt 4 ]; then
                          log "( ︶︿︶) buhhhhh...... ${TRANSFERS} are running"
                       elif [ ${UPLOADSPEED} -gt ${BWLIMITSET} ]; then
                          log "Upload Bandwith is reached || wait for next loop ( ︶︿︶)_╭∩╮"
                       else
                          log "uhhhii ... damm some is wrong"
                       fi
                       sleep 5
                     fi
                else
                    log "File not found: ${i}"
                    continue
                fi
            fi
            log "Sleeping 5s before looking at next file"
            sleep 5
        done
        log "Finished looking for files, sleeping 5 secs"
    else
        log "Nothing to upload, sleeping 5 secs"
    fi
    sleep 5
done

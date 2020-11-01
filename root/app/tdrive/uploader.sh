#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2020, MrDoob
# All rights reserved.
## function source
source /app/functions/functions.sh
#Make sure all the folders we need are created
base_folder_tdrive
downloadpath=/move
path=/config/keys/
MOVE_BASE=${MOVE_BASE:-/}
# Check encryption status
ENCRYPTED=${ENCRYPTED:-false}
if [[ "${ENCRYPTED}" == "false" ]]; then
 if grep -q GDSA01C /config/rclone/rclone-docker.conf && grep -q GDSA02C /config/rclone/rclone-docker.conf; then
    ENCRYPTED=true
 fi
fi
ADDITIONAL_IGNORES=${ADDITIONAL_IGNORES}
BASICIGNORE="! -name '*partial~' ! -name '*_HIDDEN~' ! -name '*.fuse_hidden*' ! -name '*.lck' ! -name '*.version' ! -path '.unionfs-fuse/*' ! -path '.unionfs/*' ! -path '**.inProgress/**'"
DOWNLOADIGNORE="! -path '**torrent/**' ! -path '**nzb/**' ! -path '**backup/**' ! -path '**nzbget/**' ! -path '**jdownloader2/**' ! -path '**sabnzbd/**' ! -path '**rutorrent/**' ! -path '**deluge/**' ! -path '**qbittorrent/**' ! -path '**-vpn/**' ! -path '**_UNPACK_**'"
if [ "${ADDITIONAL_IGNORES}" == 'null' ]; then
   ADDITIONAL_IGNORES=""
fi
discord_start_send_tdrive
remove_old_files_start_up
cleanup_start
bc_start_up_test
#### Generates the GDSA List from the Processed Keys
# shellcheck disable=SC2003
# shellcheck disable=SC2006
# shellcheck disable=SC2207
# shellcheck disable=SC2012
# shellcheck disable=SC2086
# shellcheck disable=SC2196
GDSAARRAY=(`ls -la ${path} | awk '{print $9}' | egrep '(PG|GD|GS)'`)
# shellcheck disable=SC2003
GDSACOUNT=$(expr ${#GDSAARRAY[@]} - 1)
# Check to see if we have any keys
# shellcheck disable=SC2086
if [ ${GDSACOUNT} -lt 1 ]; then
   log "No accounts found to upload with, Exit" 
   exit 1
fi
# Grabs vars from files
if [ -e /config/vars/lastGDSA ]; then
   GDSAUSE=$(cat /config/vars/lastGDSA)
   GDSAAMOUNT=$(cat /config/vars/gdsaAmount)
else
   GDSAUSE=0
   GDSAAMOUNT=0
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
    #Find files to transfer
    IFS=$'\n'
    mapfile -t files < <(eval find ${downloadpath} -type f ${BASICIGNORE} ${DOWNLOADIGNORE} ${ADDITIONAL_IGNORES})
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
                    # Check if we have any upload slots available
                    # shellcheck disable=SC2010
                    TRANSFERS=$(ls -la /config/pid/ | grep -c trans)
                    # shellcheck disable=SC2086
                    test1=$(vnstat -i eth0 -tr 2 | awk '$1 == "tx" {print $3}')
                    if [ ${test1} != "MB/s" ]; then
                        UPLOADSPEED=1
                    else
                        UPLOADSPEED=$(vnstat -i eth0 -tr 5 | awk '$1 == "tx" {print $2}' | sed -r 's/([^0-9]*([0-9]*)){1}.*/\2/')
                    fi
                     if [[ ! ${TRANSFERS} -ge 4 && ! ${UPLOADSPEED} -ge ${BWLIMITSET} ]]; then
                        log "Starting upload of ${i}"
                        # Append filesize to GDSAAMOUNT
                        FILESIZE2=$(stat -c %s "${i}")
                        GDSAAMOUNT=$(echo "${GDSAAMOUNT} + ${FILESIZE2}" | bc)
                        # Set gdsa as crypt or not
                        if [ ${ENCRYPTED} == "true" ]; then
                            GDSA_TO_USE="${GDSAARRAY[$GDSAUSE]}C"
                        else
                            GDSA_TO_USE="${GDSAARRAY[$GDSAUSE]}"
                        fi
                        # Run upload script demonised
                        #UPLOADSPEED=$(vnstat -i eth0 -tr 5 | awk '$1 == "tx" {print $2}' | sed -r 's/([^0-9]*([0-9]*)){1}.*/\2/')
                        UPLOADFILE=$(echo $(( ((${BWLIMITSET}-${UPLOADSPEED})) | bc )) | sed -r 's/([^0-9]*([0-9]*)){1}.*/\2/')
                        #FILEBASE=$(basename "${i}")
                        echo ${UPLOADFILE} >> /config/json/$(basename "${i}").bwlimit
                        /app/uploader/upload.sh "${i}" "${GDSA_TO_USE}" &
                        PID=$!
                        FILEBASE=$(basename "${i}")
                        # Add transfer to pid directory
                        echo "${PID}" > "/config/pid/${FILEBASE}.trans"
                        # Increase or reset $GDSAUSE?
                        # shellcheck disable=SC2086
                        if [ ${GDSAAMOUNT} -gt "783831531520" ]; then
                           log "${GDSAARRAY[$GDSAUSE]} has hit 730GB switching to next SA"
                           if [ "${GDSAUSE}" -eq "${GDSACOUNT}" ]; then
                              GDSAUSE=0
                              GDSAAMOUNT=0
                            else
                               GDSAUSE=$(("${GDSAUSE}" + 1))
                               GDSAAMOUNT=0
                            fi
                            # Record next GDSA in case of crash/reboot
                            echo "${GDSAUSE}" >/config/vars/lastGDSA
                         fi
                         log "${GDSAARRAY[${GDSAUSE}]} is now $(echo "${GDSAAMOUNT}/1024/1024/1024" | bc -l)"
                         # Record GDSA transfered in case of crash/reboot
                         echo "${GDSAAMOUNT}" >/config/vars/gdsaAmount
                    else
                        log "Already ${TRANSFERS} transfers running with ${UPLOADSPEED}MB waiting for next loop"
                        break
                    fi
                else
                    log "File not found: ${i}"
                    continue
                fi
            fi
        done
        log "Finished looking for files, sleeping 5 secs"
    else
        log "Nothing to upload, sleeping 5 secs"
    fi
    sleep 5
done

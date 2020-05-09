#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Copyright (c) 2019, PhysK
# All rights reserved.
# Logging Function
function log() {
    echo "[Uploader] ${1}"
}
downloadpath=/move
IFS=$'\n'
FILE=$1
GDSA=$2
log "[Upload] Upload started for $FILE using $GDSA"
STARTTIME=$(date +%s)
FILEBASE=$(basename "${FILE}")
FILEDIR=$(dirname "${FILE}" | sed "s#${downloadpath}/##g")
BWLIMITFILE="/app/plex/bwlimit.plex"
JSONFILE="/config/json/${FILEBASE}.json"
PLEX=${PLEX}
GCE=${GCE}
DISCORD_WEBHOOK_URL=${DISCORD_WEBHOOK_URL}
DISCORD_ICON_OVERRIDE=${DISCORD_ICON_OVERRIDE}
DISCORD_NAME_OVERRIDE=${DISCORD_NAME_OVERRIDE}

CHECKERS="$((${UPLOADS}*2))"

# add to file lock to stop another process being spawned while file is moving
echo "lock" >"${FILE}.lck"
#get Human readable filesize
HRFILESIZE=$(stat -c %s "${FILE}" | numfmt --to=iec-i --suffix=B --padding=7)
REMOTE=$GDSA
log "[Upload] Uploading ${FILE} to ${REMOTE}"
LOGFILE="/config/logs/${FILEBASE}.log"
##bwlimitpart
if [ ${PLEX} == 'true' ]; then
    BWLIMITSPEED="$(cat ${BWLIMITFILE})"
    BWLIMIT="--bwlimit=${BWLIMITSPEED}"
elif [ ${GCE} == 'true' ]; then
    UPLOADS=${UPLOADS}
    BWLIMIT=""
elif [ ${BWLIMITSET} != 'null' ]; then
    UPLOADS=${UPLOADS}
    BWLIMITSET=${BWLIMITSET}
    BWLIMITSPEED="$((${BWLIMITSET}/${UPLOADS}))"
    BWLIMIT="--bwlimit=${BWLIMITSPEED}M"
else
    BWLIMIT=""
fi

#create and chmod the log file so that webui can read it
touch "${LOGFILE}"
chmod 777 "${LOGFILE}"
#update json file for Uploader GUI
echo "{\"filedir\": \"${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"uploading\",\"logfile\": \"${LOGFILE}\",\"gdsa\": \"${GDSA}\"}" >"${JSONFILE}"
log "[Upload] Starting Upload"
rclone_move() {
   rclone_command=$(
    rclone moveto --tpslimit 6 --checkers=${CHECKERS} \
		--config /config/rclone-docker.conf \
		--log-file="${LOGFILE}" --log-level INFO --stats 2s \
		--drive-chunk-size=${CHUNK}M ${BWLIMIT} \
		"${FILE}" "${REMOTE}:${FILEDIR}/${FILEBASE}"
    )
    echo "$rclone_command"
  }
rclone_move
ENDTIME=$(date +%s)
if [ "${RC_ENABLED}" == "true" ]; then
    sleep 10s
    rclone rc vfs/forget dir="${FILEDIR}" --user "${RC_USER:-user}" --pass "${RC_PASS:-xxx}" --no-output
fi
#update json file for Uploader GUI
echo "{\"filedir\": \"/${FILEDIR}\",\"filebase\": \"${FILEBASE}\",\"filesize\": \"${HRFILESIZE}\",\"status\": \"done\",\"gdsa\": \"${GDSA}\",\"starttime\": \"${STARTTIME}\",\"endtime\": \"${ENDTIME}\"}" >"${JSONFILE}"
  if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
    rclone_sani_command="$(echo $rclone_command | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')" # Remove all escape sequences
    # Notifications assume following rclone ouput: 
    # Transferred: 0 / 0 Bytes, -, 0 Bytes/s, ETA - Errors: 0 Checks: 0 / 0, - Transferred: 0 / 0, - Elapsed time: 0.0s
    transferred_amount=${rclone_sani_command#*Transferred: }
    transferred_amount=${transferred_amount%% /*}

    send_notification() {
      output_transferred_main=${rclone_sani_command#*Transferred: }
      output_transferred_main=${output_transferred_main% Errors*}
      output_errors=${rclone_sani_command#*Errors: }
      output_errors=${output_errors% Checks*}
      output_checks=${rclone_sani_command#*Checks: }
      output_checks=${output_checks% Transferred*}
      output_transferred=${rclone_sani_command##*Transferred: }
      output_transferred=${output_transferred% Elapsed*}
      output_elapsed=${rclone_sani_command##*Elapsed time: }
      
      notification_data='{
        "username": "'"${DISCORD_NAME_OVERRIDE}"'",
        "avatar_url": "'"${DISCORD_ICON_OVERRIDE}"'",
        "content": null,
        "embeds": [
          {
            "title": "Rclone Upload Task: Success!",
            "color": 4094126,
            "fields": [
              {
                "name": "Transferred",
                "value": "'"$output_transferred_main"'"
              },
              {
                "name": "Errors",
                "value": "'"$output_errors"'"
              },
              {
                "name": "Checks",
                "value": "'"$output_checks"'"
              },
              {
                "name": "Transferred",
                "value": "'"$output_transferred"'"
              },
              {
                "name": "Elapsed time",
                "value": "'"$output_elapsed"'"
              }
            ],
            "thumbnail": {
              "url": null
            }
          }
        ]
      }'
      /usr/bin/curl -H "Content-Type: application/json" -d "$notification_data" ${DISCORD_WEBHOOK_URL}
    }
  fi
if [ ${DISCORD_WEBHOOK_URL} != 'null' ]; then
send_notification
fi
log "[Upload] Upload complete for $FILE, Cleaning up"
#remove file lock
rm -f "${FILE}.lck"
rm -f "${LOGFILE}"
rm -f "/config/pid/${FILEBASE}.trans"
find "${downloadpath}" -mindepth 2 -type d -empty -delete
sleep 30
rm -f "${JSONFILE}"

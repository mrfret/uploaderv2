#!/bin/bash
#
# Title:      AwesomeMediaGroupe
# Author(s):  AwesomeMediaGroupe
# License:    Copyright (c) 2020 AwesomeMediaGroupe
################################################################################

plex_script_root_folder="/app/plex"
PLEX_PREFERENCE_FILE=${PLEX_PREFERENCE_FILE}
PLEX_SERVER_IP=${PLEX_SERVER_IP}
PLEX_SERVER_PORT=${PLEX_SERVER_PORT}
touch ${plex_script_root_folder}/bwlimit.plex
touch ${plex_script_root_folder}/plex.streams

 while true; do
		plex_script_root_folder="/app/plex"
		PLEX_PREFERENCE_FILE=${PLEX_PREFERENCE_FILE}
		PLEX_SERVER_IP=${PLEX_SERVER_IP}
		PLEX_SERVER_PORT=${PLEX_SERVER_PORT}
		touch ${plex_script_root_folder}/bwlimit.plex
		touch ${plex_script_root_folder}/plex.streams

       if [[ -e "${PLEX_PREFERENCE_FILE}" ]]; then
       PLEX_TOKEN=$(cat "${PLEX_PREFERENCE_FILE}" | sed -e 's;^.* PlexOnlineToken=";;' | sed -e 's;".*$;;' | tail -1)
       PLEX_PLAYS=$(curl --silent "http://${PLEX_SERVER_IP}:${PLEX_SERVER_PORT}/status/sessions" -H "X-Plex-Token: $PLEX_TOKEN" | xmllint --xpath 'string(//MediaContainer/@size)' -)
       echo "${PLEX_PLAYS}" >${plex_script_root_folder}/plex.streams
        if [[ "${PLEX_PLAYS}" -eq "2" ]]; then
             echo "13M" >${plex_script_root_folder}/bwlimit.plex
        elif [[ "${PLEX_PLAYS}" -eq "3" ]]; then
             echo "12M" >${plex_script_root_folder}/bwlimit.plex
        elif [[ "${PLEX_PLAYS}" -eq "4" ]]; then
             echo "10M" >${plex_script_root_folder}/bwlimit.plex
        elif [[ "${PLEX_PLAYS}" -eq "6" ]]; then
             echo "8M" >${plex_script_root_folder}/bwlimit.plex
        elif [[ "${PLEX_PLAYS}" -gt "6" ]]; then
             echo "5M" >${plex_script_root_folder}/bwlimit.plex
       else echo "40M" >${plex_script_root_folder}/bwlimit.plex; fi
      else echo "40M" >${plex_script_root_folder}/bwlimit.plex; fi
         chown -cR 1000:1000 ${plex_script_root_folder} 
		 chmod -cR 777 ${plex_script_root_folder}
 done
 
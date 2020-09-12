#!/bin/bash
#
############################################################################### 
# Author            :  Louwrentius
# Contact           : louwrentius@gmail.com
# Initial release   : August 2011
# Licence           : Simplified BSD License
############################################################################### 
MOUNT="/move/"
CAPACITY_LIMIT=${CAPACITY_LIMIT}
MAX_CYCLES=10
CAPACITY_LIMIT=${CAPACITY_LIMIT:-75}
if [[ ${CAPACITY_LIMIT} == 'null' ]]; then
    CAPACITY_LIMIT=75
else
    CAPACITY_LIMIT=${CAPACITY_LIMIT}
fi
reset () {
    CYCLES=0
    OLDEST_FILE=""
    OLDEST_DATE=0
}
reset
check_capacity () {
    USAGE=$(df -h | grep "$MOUNT" | awk '{ print $5 }' | sed s/%//g)
    if [ "$USAGE" -gt "${CAPACITY_LIMIT}" ]; then
        return 0
    else
        return 1
    fi
}
check_age () {
    FILE="$1"
    FILE_DATE=$(stat -c %Z "$FILE")
    NOW=$(date +%s)
    AGE=$((NOW-FILE_DATE))
    if [ "$AGE" -gt "$OLDEST_DATE" ]
    then
        export OLDEST_DATE="$AGE"
        export OLDEST_FILE="$FILE"
    fi
}
process_file () {
    FILE="$1"
    rm -f "$FILE"
}
while check_capacity
do
    if [ "$CYCLES" -gt "$MAX_CYCLES" ]; then
        echo "Error: after $MAX_CYCLES deleted files still not enough free space."
        exit 1
    fi
    reset
    FILES=$(find "$MOUNT" -type f)
    IFS=$'\n'
    for x in $FILES
    do
        check_age "$x"
    done
    if [ -e "$OLDEST_FILE" ]; then
        process_file "$OLDEST_FILE"
    fi
    ((CYCLES++))
done

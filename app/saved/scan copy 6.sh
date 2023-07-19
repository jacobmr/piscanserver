#!/bin/bash
set -x
DATE=$(date +"%Y%m%d_%H%M")

# Get directory of this script
DIR="$(dirname "$0")"

# Check if the script is already running
LOCKFILE="/tmp/scan_script.lock"
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# Scan with the given scanner and settings
# Arguments: scanner settings_file prefix
# Scan with the given scanner and settings
# Arguments: scanner settings_file prefix
scan() {
    SCANNER=$1
    SETTINGS_FILE=$2
    PREFIX=$3
    RCLONE_REMOTE=$4
    SOURCE="ADF"
    BRIGHTNESS=""
    CONTRAST=""
    THRESHOLD=""

    # Read from settings file
    if [ -f $SETTINGS_FILE ]; then
        while IFS= read -r line
        do
            if [[ $line == MODE=* ]]; then
                MODE=${line#MODE=}
            elif [[ $line == RESOLUTION=* ]]; then
                RESOLUTION=${line#RESOLUTION=}
            elif [[ $line == ERRORS=* ]]; then
                ERRORS=${line#ERRORS=}
            elif [[ $line == SOURCE=* ]]; then
                SOURCE=${line#SOURCE=}
            elif [[ $line == BRIGHTNESS=* ]]; then
                BRIGHTNESS=${line#BRIGHTNESS=}
            elif [[ $line == CONTRAST=* ]]; then
                CONTRAST=${line#CONTRAST=}
            elif [[ $line == THRESHOLD=* ]]; then
                THRESHOLD=${line#THRESHOLD=}
            fi
        done < "$SETTINGS_FILE"
    fi

    # Perform the scan
    CMD="scanimage -d \"$SCANNER\" --format=png --resolution $RESOLUTION --mode $MODE --source $SOURCE --batch=$SCAN_FOLDER/${PREFIX}scan-page-%d.png"
    if [[ -n $BRIGHTNESS ]]; then
        CMD+=" --brightness $BRIGHTNESS"
    fi
    if [[ -n $CONTRAST ]]; then
        CMD+=" --contrast $CONTRAST"
    fi
    if [[ -n $THRESHOLD ]]; then
        CMD+=" --threshold $THRESHOLD"
    fi
    if [[ $ERRORS == "no" ]]; then
        CMD+=" 2>/dev/null"
    fi
    eval $CMD

    # Check if the scan succeeded and move the files
    if [ -f $SCAN_FOLDER/${PREFIX}scan-page-1.png ]; then
        convert $SCAN_FOLDER/${PREFIX}scan-page-*.png $SCAN_FOLDER/$PREFIX$DATE.pdf
        rclone move "$SCAN_FOLDER/$PREFIX$DATE.pdf" "$RCLONE_REMOTE"
        rm $SCAN_FOLDER/${PREFIX}scan-page-*.png
    fi
}


# Parsing scan-config.txt file and calling scan function for each scanner
SCAN_FOLDER="/home/jacob/scan"
while IFS= read -r line; do
    if [[ $line == Scanner* ]]; then
        unset SCANNER SETTINGS_FILE RCLONE_REMOTE
    elif [[ $line == SCANNER=* ]]; then
        SCANNER=${line#SCANNER=}
        SCANNER=${SCANNER//\"/}  # Remove double quotes
    elif [[ $line == SETTINGS_FILE=* ]]; then
        SETTINGS_FILE=${line#SETTINGS_FILE=}
        SETTINGS_FILE=${SETTINGS_FILE//\"/}  # Remove double quotes
    elif [[ $line == RCLONE_REMOTE=* ]]; then
        RCLONE_REMOTE=${line#RCLONE_REMOTE=}
        RCLONE_REMOTE=${RCLONE_REMOTE//\"/}  # Remove double quotes
    fi

    if [[ -n $SCANNER ]] && [[ -n $SETTINGS_FILE ]] && [[ -n $RCLONE_REMOTE ]]; then
        # Generate a unique prefix for each scanner
        PREFIX=$(echo $SCANNER | md5sum | cut -f1 -d' ')
        scan "$SCANNER" $SETTINGS_FILE $PREFIX $RCLONE_REMOTE

    fi
done < "$DIR/scan-config.txt"

# Clean up
rm -f ${LOCKFILE}

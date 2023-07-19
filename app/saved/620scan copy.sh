#!/bin/bash
set -x
DATE=$(date +"%Y%m%d_%H%M")

# Get directory of this script
DIR="$(dirname "$0")"
source $DIR/scan-config.txt

# Check if the script is already running
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# Scan with the given scanner and settings
# Arguments: scanner settings_file prefix
scan() {
    SCANNER=$1
    SETTINGS_FILE=$2
    PREFIX=$3


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
             elif [[ $line == REMOTE=* ]]; then
                RCLONE_REMOTE=${line#REMOTE=}
            fi
        done < "$SETTINGS_FILE"
    fi

    # Perform the scan
    if [[ $SCANNER == $FJ_SCANNER ]]; then
        CMD="scanimage -d '$SCANNER' --source 'ADF Duplex' --format=png --batch=$SCAN_FOLDER/${PREFIX}scan-page-%d.png"
    else
        CMD="scanimage -d '$SCANNER' --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=$SCAN_FOLDER/${PREFIX}scan-page-%d.png"
        if [[ $ERRORS == "no" ]]; then
            CMD+=" 2>/dev/null"
        fi
    fi
    eval $CMD
}

# Perform the scans
scan $HP_SCANNER $HP_SETTINGS_FILE "H"
if [ -f $SCAN_FOLDER/Hscan-page-1.png ]; then
    # The scan succeeded
    convert $SCAN_FOLDER/Hscan-page-*.png $SCAN_FOLDER/H$DATE.pdf
    rclone move "$SCAN_FOLDER/H$DATE.pdf" "$RCLONE_REMOTE"
    rm $SCAN_FOLDER/Hscan-page-*.png
fi

#scan $FJ_SCANNER $FJ_SETTINGS_FILE "F"
scan "$FJ_SCANNER" "$FJ_SETTINGS_FILE" "F"
if [ -f $SCAN_FOLDER/Fscan-page-1.png ]; then
    # The scan succeeded
    convert $SCAN_FOLDER/Fscan-page-*.png $SCAN_FOLDER/F$DATE.pdf
    rclone move "$SCAN_FOLDER/F$DATE.pdf" "$RCLONE_REMOTE"
    rm $SCAN_FOLDER/Fscan-page-*.png
fi

# Clean up
rm -f ${LOCKFILE}

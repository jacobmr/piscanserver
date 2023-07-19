#!/bin/bash
set -x
DATE=$(date +"%Y%m%d_%H%M")

# Get directory of this script
DIR="$(dirname "$0")"

# Function to parse config file and get options for scanimage
parse_config() {
    awk -F'--' '{print $2}' "$1" | awk -F' ' '{print $1, $2}' | tr -d '[]' | tr '\n' ' '
}

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
scan() {
    SCANNER=$1
    SETTINGS_FILE=$2
    PREFIX=$3
    RCLONE_REMOTE=$4
    OPTIONS=$(python3 parse_config.py $SETTINGS_FILE)

    # Perform the scan
    CMD="scanimage -d \"$SCANNER\" --format=png $OPTIONS --batch=$SCAN_FOLDER/${PREFIX}scan-page-%d.png"
    eval $CMD

    # Check if the scan succeeded and move the files
    if [ -f $SCAN_FOLDER/${PREFIX}scan-page-1.png ]; then
        convert $SCAN_FOLDER/${PREFIX}scan-page-*.png $SCAN_FOLDER/$PREFIX$DATE.pdf
        rclone move "$SCAN_FOLDER/$PREFIX$DATE.pdf" "$RCLONE_REMOTE"
        rm $SCAN_FOLDER/${PREFIX}scan-page-*.png
    fi
}

# Parsing scan-config.txt file and calling scan function for each scanner
SCAN_FOLDER=$DIR
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

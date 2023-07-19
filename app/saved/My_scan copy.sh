#!/bin/bash
DATE=$(date +"%Y%m%d_%H%M")

# Scanner specifications
HP_SCANNER="hpaio:/usb/HP_LaserJet_M2727nf_MFP?serial=00CND881108V"
FJ_SCANNER="fujitsu:ScanSnap S1500:34682"

# Lock file path
LOCKFILE=/tmp/scan_script.lock

# Check if the script is already running
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "Scan script is already running."
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
            fi
        done < $SETTINGS_FILE
    fi
    # Perform the scan
    if [[ $SCANNER == $FJ_SCANNER ]]; then
        CMD="scanimage -d \"$SCANNER\" --source 'ADF Duplex' --format=png --batch=/home/jacob/scan/$PREFIX-scan-page-%d.png"
    else
        if [[ $ERRORS == "yes" ]]; then
            CMD="scanimage -d \"$SCANNER\" --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/$PREFIX-scan-page-%d.png"
        else
            CMD="scanimage -d \"$SCANNER\" --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/$PREFIX-scan-page-%d.png 2>/dev/null"
        fi
    fi
    eval $CMD
}

# Perform the scans
scan "$HP_SCANNER" /home/jacob/scan-settings_HP.txt "H"
if [ -f /home/jacob/scan/H-scan-page-1.png ]; then
    # The scan succeeded
    convert /home/jacob/scan/H-scan-page-*.png /home/jacob/scan/H-$DATE.pdf
    rclone move /home/jacob/scan/H-$DATE.pdf jmr:/Family\ Room/scan
    rm /home/jacob/scan/H-scan-page-*.png
fi

scan "$FJ_SCANNER" /home/jacob/scan-settings_FJ.txt "F"
if [ -f /home/jacob/scan/F-scan-page-1.png ]; then
    # The scan succeeded
    convert /home/jacob/scan/F-scan-page-*.png /home/jacob/scan/F-$DATE.pdf
    rclone move /home/jacob/scan/F-$DATE.pdf jmr:/Family\ Room/scan
    rm /home/jacob/scan/F-scan-page-*.png
fi

# Clean up
rm -f ${LOCKFILE}

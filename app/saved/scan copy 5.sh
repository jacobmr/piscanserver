#!/bin/bash
DATE=$(date +"%Y%m%d_%H%M")

# Scanner specifications
HP_SCANNER="hpaio:/usb/HP_LaserJet_M2727nf_MFP?serial=00CND881108V"
FJ_SCANNER="fujitsu:ScanSnap_S1500:34682"

# Function to scan with the given scanner and settings
# Arguments: scanner settings_file scan_prefix
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
    if [[ $ERRORS == "yes" ]]; then
        scanimage -d $SCANNER --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/${PREFIX}-scan-page-%d.png
    else
        scanimage -d $SCANNER --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/${PREFIX}-scan-page-%d.png 2>/dev/null
    fi
}

# Function to convert and move scanned images
# Arguments: scan_prefix
post_scan() {
    PREFIX=$1
    if [ -f /home/jacob/scan/${PREFIX}-scan-page-1.png ]; then
        convert /home/jacob/scan/${PREFIX}-scan-page-*.png /home/jacob/scan/$DATE.pdf
        rclone move /home/jacob/scan jmr:/Family\ Room/scan
        rm /home/jacob/scan/${PREFIX}-scan-page-*.png
    fi
}

# Check for any existing PDFs in the scan directory
for pdf_file in /home/jacob/scan/*.pdf; do
  if [ -f "$pdf_file" ]; then
    echo "Found stranded PDF: $pdf_file. Attempting to move to Dropbox..."
    rclone move "$pdf_file" jmr:/Family\ Room/scan
  fi
done

# Perform the scans
scan $HP_SCANNER /home/jacob/scan-settings_HP.txt "hp"
post_scan "hp"

scan $FJ_SCANNER /home/jacob/scan-settings_FJ.txt "fj"
post_scan "fj"

#!/bin/bash


LOCKFILE=/tmp/scan_lockfile

# Check if lock file exists
if [ -e ${LOCKFILE} ]; then
    echo "Scan script is already running. Exiting."
    exit 1
else
    # Create the lock file
    touch ${LOCKFILE}
    echo "Lock file created. Starting scan script."


DATE=$(date +"%Y%m%d_%H%M")

# Scanner specifications
HP_SCANNER="hpaio:/usb/HP_LaserJet_M2727nf_MFP?serial=00CND881108V"
FJ_SCANNER="fujitsu:ScanSnap_S1500:34682"

# Check for any existing PDFs in the scan directory
for pdf_file in /home/jacob/scan/*.pdf; do
  if [ -f "$pdf_file" ]; then
    echo "Found stranded PDF: $pdf_file. Attempting to move to Dropbox..."
    rclone move "$pdf_file" jmr:/Family\ Room/scan
  fi
done

# ... rest of your script continues here ...

# Scan with the given scanner and settings
# Arguments: scanner settings_file prefix
scan() {
    SCANNER=$1
    SETTINGS_FILE=$2
    PREFIX=$3
    SOURCE="ADF"
    # Check if Fujitsu
    if [[ $SCANNER == *fujitsu* ]]; then
        SOURCE="ADF Duplex" # or "ADF Front"
    fi

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
    
  
  if [[ $ERRORS == "yes" ]]; then
    scanimage -d $SCANNER --format=png --resolution $RESOLUTION --mode $MODE --source $SOURCE --batch=/home/jacob/scan/${PREFIX}-scan-page-%d.png || echo "Failed to scan with $SCANNER"
else
    scanimage -d $SCANNER --format=png --resolution $RESOLUTION --mode $MODE --source $SOURCE --batch=/home/jacob/scan/${PREFIX}-scan-page-%d.png 2>/dev/null || echo "Failed to scan with $SCANNER"
fi

  
    
  #  if [[ $ERRORS == "yes" ]]; then
  #  scanimage -d $SCANNER --format=png --resolution $RESOLUTION --mode $MODE --source $SOURCE --batch=/home/jacob/scan/${PREFIX}-scan-page-%d.png || echo "Failed to scan with $SCANNER"
#else
#    scanimage -d $SCANNER --format=png --resolution $RESOLUTION --mode $MODE --source $SOURCE --batch=/home/jacob/scan/${PREFIX}-scan-page-%d.png 2>/dev/null || echo "Failed to scan with $SCANNER"
#fi

}

# Perform the scans
scan $HP_SCANNER /home/jacob/scan-settings_HP.txt hp
if [ -f /home/jacob/scan/hp-scan-page-1.png ]; then
    # The scan succeeded
    convert /home/jacob/scan/hp-scan-page-*.png /home/jacob/scan/$DATE.pdf

    # Delete the individual scanned image files
    rm /home/jacob/scan/hp-scan-page-*.png
fi

scan $FJ_SCANNER /home/jacob/scan-settings_FJ.txt fj
if [ -f /home/jacob/scan/fj-scan-page-1.png ]; then
    # The scan succeeded
    convert /home/jacob/scan/fj-scan-page-*.png /home/jacob/scan/$DATE.pdf
    
    # Delete the individual scanned image files
    rm /home/jacob/scan/fj-scan-page-*.png
fi

# Move the PDF files to Dropbox
rclone move /home/jacob/scan/*.pdf jmr:/Family\ Room/scan

# Delete any remaining PNG files
if ls /home/jacob/scan/*-scan-page-*.png 1> /dev/null 2>&1; then
    rm /home/jacob/scan/*-scan-page-*.png
fi


    # Delete the lock file at the end
    rm ${LOCKFILE}
    echo "Scan script finished. Lock file deleted."
    exit 0
fi

#!/bin/bash
DATE=$(date +"%Y%m%d_%H%M")

# Default values
MODE="Lineart"  # Black and white
RESOLUTION="300"  # 300 DPI
ERRORS="no"  # Discard errors

# Read from settings file
if [ -f /home/jacob/scan-settings.txt ]; then
    while IFS= read -r line
    do
        if [[ $line == MODE=* ]]; then
            MODE=${line#MODE=}
        elif [[ $line == RESOLUTION=* ]]; then
            RESOLUTION=${line#RESOLUTION=}
        elif [[ $line == ERRORS=* ]]; then
            ERRORS=${line#ERRORS=}
        fi
    done < /home/jacob/scan-settings.txt
fi

# Perform the scan
if [[ $ERRORS == "yes" ]]; then
    scanimage -d hpaio:/usb/HP_LaserJet_M2727nf_MFP?serial=00CND881108V --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/scan-page-%d.png
else
    scanimage -d hpaio:/usb/HP_LaserJet_M2727nf_MFP?serial=00CND881108V --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/scan-page-%d.png 2>/dev/null
fi



# Perform the scan
# if [[ $ERRORS == "yes" ]]; then
#     scanimage --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/scan-page-%d.png
# else
#     scanimage --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/scan-page-%d.png 2>/dev/null
# fi

# Check if the first page scan succeeded (since --batch doesn't return an error if later pages fail)
if [ -f /home/jacob/scan/scan-page-1.png ]; then
    # The scan succeeded
    convert /home/jacob/scan/scan-page-*.png /home/jacob/scan/$DATE.pdf
    rclone move /home/jacob/scan jmr:/Family\ Room/scan
else
    # The scan failed, so delete the empty PNG files if they exist
    if ls /home/jacob/scan/scan-page-*.png 1> /dev/null 2>&1; then
        rm /home/jacob/scan/scan-page-*.png
    fi
fi


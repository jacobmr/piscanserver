#!/bin/bash
DATE=$(date +"%Y%m%d_%H%M")

# Default values
MODE="Lineart"  # Black and white
RESOLUTION="300"  # 300 DPI
ERRORS="no"  # Discard errors

# Read from settings file and
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
    scanimage --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/scan-page-%d.png
else
    scanimage --format=png --resolution $RESOLUTION --mode $MODE --source ADF --batch=/home/jacob/scan/scan-page-%d.png 2>/dev/null
fi

# Check if the first page scan succeeded (since --batch doesn't return an error if later pages fail)
if [ -f /home/jacob/scan/scan-page-1.png ]; then
    # The scan succeeded
    convert /home/jacob/scan/scan-page-*.png /home/jacob/scan/$DATE.pdf
    rm /home/jacob/scan/scan-page-*.png
    rclone move /home/jacob/scan scan:/Family\ Room/scan
    rclone delete scan:/Family\ Room/scan --include "*.png"
else
    # The scan failed, so delete the empty PNG files
    rm /home/jacob/scan/scan-page-*.png
fi

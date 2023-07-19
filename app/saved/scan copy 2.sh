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
    scanimage --format=png --resolution $RESOLUTION --mode $MODE --source ADF > /home/jacob/scan/$DATE.png
else
    scanimage --format=png --resolution $RESOLUTION --mode $MODE --source ADF > /home/jacob/scan/$DATE.png 2>/dev/null
fi

if [ $? -eq 0 ]; then
    # The scan succeeded
    convert /home/jacob/scan/$DATE.png /home/jacob/scan/$DATE.pdf
    rm /home/jacob/scan/$DATE.png
    rclone move /home/jacob/scan jmr:/Family\ Room/scan
    rclone delete jmr:/Family\ Room/scan --include "*.png"
else
    # The scan failed, so delete the empty PNG file
    rm /home/jacob/scan/$DATE.png
fi

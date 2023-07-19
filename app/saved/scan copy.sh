#!/bin/bash
DATE=$(date +"%Y%m%d_%H%M")

# Default values
MODE="Lineart"  # Scan mode
RESOLUTION="300"  # DPI
SOURCE="ADF"  # Scan source
BRIGHTNESS="0"  # Brightness
CONTRAST="0"  # Contrast
COMPRESSION="JPEG"  # Compression
JPEG_QUALITY="50"  # JPEG Quality (only active if compression is set to JPEG)
ERRORS="no"  # Display errors

# Read from settings file
if [ -f /home/jacob/scan-settings.txt ]; then
    while IFS= read -r line
    do
        if [[ $line == MODE=* ]]; then
            MODE=${line#MODE=}
        elif [[ $line == RESOLUTION=* ]]; then
            RESOLUTION=${line#RESOLUTION=}
        elif [[ $line == SOURCE=* ]]; then
            SOURCE=${line#SOURCE=}
        elif [[ $line == BRIGHTNESS=* ]]; then
            BRIGHTNESS=${line#BRIGHTNESS=}
        elif [[ $line == CONTRAST=* ]]; then
            CONTRAST=${line#CONTRAST=}
        elif [[ $line == COMPRESSION=* ]]; then
            COMPRESSION=${line#COMPRESSION=}
        elif [[ $line == JPEG_QUALITY=* ]]; then
            JPEG_QUALITY=${line#JPEG_QUALITY=}
        elif [[ $line == ERRORS=* ]]; then
            ERRORS=${line#ERRORS=}
        fi
    done < /home/jacob/scan-settings.txt
fi

# Start the scan
if [[ $ERRORS == "yes" ]]; then
    scanimage --batch=/home/jacob/scan/$DATE"_%03d".png --format=png --mode $MODE --resolution $RESOLUTION --source $SOURCE --brightness $BRIGHTNESS --contrast $CONTRAST --compression $COMPRESSION $([ "$JPEG_QUALITY" ] && echo "--jpeg-quality $JPEG_QUALITY")
else
    scanimage --batch=/home/jacob/scan/$DATE"_%03d".png --format=png --mode $MODE --resolution $RESOLUTION --source $SOURCE --brightness $BRIGHTNESS --contrast $CONTRAST --compression $COMPRESSION $([ "$JPEG_QUALITY" ] && echo "--jpeg-quality $JPEG_QUALITY") 2>/dev/null
fi

if [ $? -eq 0 ]; then
    # The scan succeeded, convert each page to PDF and then combine
    convert /home/jacob/scan/$DATE*.png /home/jacob/scan/$DATE.pdf
    rm /home/jacob/scan/$DATE*.png
    rclone sync /home/jacob/scan jmr:/Family\ Room/scan
    rclone delete jmr:/Family\ Room/scan --include "*.png"
else
    # The scan failed, so delete the empty PNG files
    rm /home/jacob/scan/$DATE*.png
fi

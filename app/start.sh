#!/bin/bash
set -x
# Directory of the script
DIR="$(cd "$(dirname "$0")" && pwd)"

# Path to the configuration file
CONFIG_FILE="$DIR/scan-config.txt"

# Temporary config file for holding the new SCANNER entries
temp_config="$DIR/temp-config.txt"

# Associative array for storing RCLONE_REMOTE and SOURCE for each scanner
declare -A remotes sources configs

# Extract the values of RCLONE_REMOTE and SOURCE for each scanner
while read -r line; do
  if [[ $line == SCANNER* ]]; then
    scanner_id=${line#SCANNER=\"}
    scanner_id=${scanner_id%\"}
  elif [[ $line == SETTINGS_FILE* ]]; then
    settings=${line#SETTINGS_FILE=\"}
    settings=${settings%\"}
    configs[$scanner_id]=$settings
  elif [[ $line == RCLONE_REMOTE* ]]; then
    remote=${line#RCLONE_REMOTE=\"}
    remote=${remote%\"}
    remotes[$scanner_id]=$remote
  elif [[ $line == SOURCE* ]]; then
    source=${line#SOURCE=\"}
    source=${source%\"}
    sources[$scanner_id]=$source
  fi
done < "$CONFIG_FILE"

# Start the SCANNERS section
echo "#SCANNERS" > "$temp_config"

# Read the list of connected scanners
scanners=$(scanimage -L)

# Loop over the connected scanners
while read -r scanner; do
  scanner_id=$(echo "$scanner" | cut -d '`' -f2 | sed "s/' is.*//")

  # Skip the scanner if it's already registered
  if [[ -n "${configs[$scanner_id]}" ]]; then
    continue
  fi
  
  config_filename=$(echo "$scanner_id" | sed 's/[^a-zA-Z0-9]/_/g' | cut -c 1-10)_$(shuf -i 100-999 -n 1).txt
  config_filepath="$DIR/$config_filename"
  
  # Update its configurations
  scanimage --device "${scanner_id%\'}" -A > "$config_filepath" 2> /dev/null
  configs[$scanner_id]=$config_filepath
  echo "Created/updated configuration file for $scanner_id"
  
  # Add this scanner to the SCANNERS section
  echo "" >> "$temp_config"
  echo "Scanner" >> "$temp_config"
  echo "SCANNER=\"$scanner_id\"" >> "$temp_config"
  echo "SETTINGS_FILE=\"$config_filepath\"" >> "$temp_config"
  echo "RCLONE_REMOTE=\"${remotes[$scanner_id]}\"" >> "$temp_config"
  echo "SOURCE=\"${sources[$scanner_id]}\"" >> "$temp_config"
done <<< "$scanners"


# Create a copy of the original config file without the SCANNERS section
sed '/#SCANNERS/,/Scanner/d' "$CONFIG_FILE" > "$DIR/temp-original-config.txt"

# Replace the original config file with the copy without the SCANNERS section
mv "$DIR/temp-original-config.txt" "$CONFIG_FILE"

# Append the new SCANNERS section to the original config file
cat "$temp_config" >> "$CONFIG_FILE"

# Clean up the temporary config file
rm "$temp_config"

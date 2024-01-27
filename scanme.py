import os
import sys
import subprocess  
from datetime import datetime
import glob
import json

# Path to the virtual environment's bin directory
venv_bin_dir = '/home/jacob/app/v3/env/bin'

# Activate the virtual environment
venv_python = os.path.join(venv_bin_dir, 'python')

# Set the PATH variable to include the virtual environment's bin directory
os.environ['PATH'] = f'{venv_bin_dir}:{os.environ["PATH"]}'

# Log the Python executable path
with open('/home/jacob/python_env.log', 'w') as log_file:
    log_file.write(venv_python)

# Log the PATH variable
with open('/home/jacob/cron_path.log', 'w') as log_file:
    log_file.write(os.environ['PATH'])

# Log errors to an error log file
error_log_file = '/home/jacob/error.log'


# Define the path to the scan configuration file
config_file = "/home/jacob/app/v3/scan-config.json"

# Read the scan configuration JSON file
def read_config(file):
    with open(file, 'r') as f:
        return json.load(f)

# Parse the scan configuration JSON and extract settings
def parse_config(json_data, query):
    keys = query.strip().split('.')
    val = json_data
    for key in keys:
        val = val[key]
    return val

# Perform the scan
def perform_scan(scanner_dict, prefix):
    scanner = scanner_dict['SCANNER']
    rclone_remote = scanner_dict['RCLONE_REMOTE']

    # Define a lock file for this scanner
    # Replace all non-alphanumeric characters with "_"
    sanitized_scanner_name = ''.join(c if c.isalnum() else '_' for c in scanner)
    lock_file = f"/tmp/scan_script_{sanitized_scanner_name}.lock"

    # Check if a scan is already in progress for this scanner
    if os.path.isfile(lock_file):
        print(f"A scan is already in progress for {scanner}, skipping.")
        return

    # Create a lock file to prevent concurrent scanning
    open(lock_file, 'a').close()

    # Define the scanner settings
    settings = {}
    if 'fujitsu' in scanner.lower():
        settings = {
            "source": "ADF Duplex",
            "mode": "Gray",
            "resolution": "300"
        }
    elif 'hp' in scanner.lower():
        settings = {
            "source": "Duplex",
            "mode": "Gray",
            "resolution": "300"
        }

    # Dynamically construct the scanimage command
    #comment the next line for batch
    #cmd = f'scanimage -d "{scanner}" --format=png --batch-count=4' 
    #uncomment the next line for batch
    cmd = f'scanimage -d "{scanner}" --format=png'
    for setting_name, setting_value in settings.items():
        cmd += f" --{setting_name.lower()}='{setting_value}'"
    cmd += f' --batch="./scans/{prefix}scan-page-%d.png"'
    # Execute the scanimage command
    # subprocess.run(cmd, shell=True)
    result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(result.stdout.decode())
    print(result.stderr.decode())

    # Check if the scan succeeded by verifying the existence of the first scan page
    if os.path.isfile(f"./scans/{prefix}scan-page-1.png"):
        # Convert scanned pages to PDF
        convert_cmd = f'convert ./scans/{prefix}scan-page-*.png ./scans/{prefix}scan.pdf'
        convert_result = subprocess.run(convert_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        print(convert_result.stdout.decode())
        print(convert_result.stderr.decode())
        if os.path.isfile(f'./scans/{prefix}scan.pdf'):
            print(f'Successfully converted images to PDF: ./scans/{prefix}scan.pdf')
        else:
            print(f'Failed to convert images to PDF')

        # Upload the PDF file to the remote destination
        rclone_command = f'rclone move "./scans/{prefix}scan.pdf" "{rclone_remote}"'
        rclone_result = subprocess.run(rclone_command, shell=True)
        # If rclone move was successful, the local PDF file should no longer exist
        if not os.path.isfile(f'./scans/{prefix}scan.pdf'):
            print(f'Successfully moved PDF to remote: {rclone_remote}')

        # Delete the scanned image files
        for file in glob.glob(f"./scans/{prefix}scan-page-*.png"):
            os.remove(file)

    # Remove the lock file
    os.remove(lock_file)


# Read the scan configuration file
config = read_config(config_file)

# Parse global settings
scan_folder = parse_config(config, 'GLOBAL.SCAN_FOLDER')

# Generate a unique prefix for the scan files
prefix = datetime.now().strftime("%Y%m%d_%H%M%S")

# Perform scans for each scanner defined in the configuration
scanners = config['SCANNERS']
for scanner_dict in scanners:
    perform_scan(scanner_dict, prefix)

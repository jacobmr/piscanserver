from flask import Flask, render_template, request
import os
import json
from pathlib import Path

app = Flask(__name__)

app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY') or 'you-will-never-guess'

# Load the global configuration file
global_config_path = Path("scan-config.txt")
with global_config_path.open() as file:
    global_config = json.load(file)

# Load the individual scanner configuration files
for scanner in global_config['SCANNERS']:
    settings_file_path = Path(scanner['SETTINGS_FILE'])
    with settings_file_path.open() as file:
        scanner['SETTINGS'] = json.load(file)

def update_and_save_settings(form_data):
    for key, value in form_data.items():
        for scanner in global_config['SCANNERS']:
            if key in scanner['SETTINGS']:
                scanner['SETTINGS'][key]['current_value'] = value
    
    # Save the new settings to the file
    with global_config_path.open('w') as file:
        json.dump(global_config, file)

@app.route('/', methods=['GET', 'POST'])
def home():
    if request.method == 'POST':
        update_and_save_settings(request.form)

    return render_template('index.html', global_config=global_config)

@app.route('/api', methods=['GET', 'POST'])
def api():
    if request.method == 'POST':
        update_and_save_settings(request.form)
    else:
        # handle URL parameters from a GET request
        update_and_save_settings(request.args)

    return 'Settings updated successfully'

if __name__ == '__main__':
    app.run(debug=True)

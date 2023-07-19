from flask import Flask, render_template, request, jsonify
from flask_wtf import FlaskForm
from wtforms import SelectField, SubmitField
from wtforms.validators import DataRequired
from flask_bootstrap import Bootstrap
import os
import requests

app = Flask(__name__)
Bootstrap(app)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY')

class SettingsForm(FlaskForm):
    mode = SelectField('Mode', choices=[('Grayscale', 'Grayscale'), ('Color', 'Color'), ('Black and White', 'Black and White')], validators=[DataRequired()])
    resolution = SelectField('Resolution', choices=[('100', '100'), ('300', '300'), ('600', '600'), ('1200', '1200')], validators=[DataRequired()])
    source = SelectField('Source', choices=[('ADF', 'ADF'), ('Flatbed', 'Flatbed')], validators=[DataRequired()])
    brightness = SelectField('Brightness', choices=[(str(i), str(i)) for i in range(-100, 101)], validators=[DataRequired()])
    contrast = SelectField('Contrast', choices=[(str(i), str(i)) for i in range(-100, 101)], validators=[DataRequired()])
    compression = SelectField('Compression', choices=[('JPEG', 'JPEG'), ('TIFF', 'TIFF'), ('PNG', 'PNG'), ('None', 'None')], validators=[DataRequired()])
    errors = SelectField('Errors', choices=[('Ignore', 'Ignore'), ('Stop', 'Stop'), ('Prompt', 'Prompt')], validators=[DataRequired()])
    submit = SubmitField('Submit')

def read_settings_from_file():
    settings_dict = {}
    with open('scan-settings.txt', 'r') as f:
        for line in f:
            key, value = line.strip().split('=')
            settings_dict[key] = value
    return settings_dict

def write_settings_to_file(settings_dict):
    with open('scan-settings.txt', 'w') as f:
        for key, value in settings_dict.items():
            f.write('%s=%s\n' % (key, value))

@app.route('/', methods=['GET', 'POST'])
def index():
    default_settings = read_settings_from_file()
    form = SettingsForm(
        mode=default_settings.get('MODE', 'Grayscale'),
        resolution=default_settings.get('RESOLUTION', '300'),
        source=default_settings.get('SOURCE', 'ADF'),
        brightness=default_settings.get('BRIGHTNESS', '0'),
        contrast=default_settings.get('CONTRAST', '0'),
        compression=default_settings.get('COMPRESSION', 'JPEG'),
        errors=default_settings.get('ERRORS', 'no')
    )
    if form.validate_on_submit():
        settings_dict = {
            "MODE": form.mode.data,
            "RESOLUTION": form.resolution.data,
            "SOURCE": form.source.data,
            "BRIGHTNESS": form.brightness.data,
            "CONTRAST": form.contrast.data,
            "COMPRESSION": form.compression.data,
            "ERRORS": form.errors.data
        }
        write_settings_to_file(settings_dict)
    return render_template('index.html', form=form)

@app.route('/api', methods=['POST'])
def update_scanner_settings():
    api_key = request.args.get('key')
    if api_key:
        settings_dict = {}
        if 'mode' in request.args:
            settings_dict['MODE'] = request.args.get('mode')
        if 'resolution' in request.args:
            settings_dict['RESOLUTION'] = request.args.get('resolution')
        if 'source' in request.args:
            settings_dict['SOURCE'] = request.args.get('source')
        if 'brightness' in request.args:
            settings_dict['BRIGHTNESS'] = request.args.get('brightness')
        if 'contrast' in request.args:
            settings_dict['CONTRAST'] = request.args.get('contrast')
        if 'compression' in request.args:
            settings_dict['COMPRESSION'] = request.args.get('compression')
        if 'errors' in request.args:
            settings_dict['ERRORS'] = request.args.get('errors')
        if settings_dict:
            # Make a request to the scanner API to update the settings
            api_url = 'http://scan.salundo.com/api/scanner'
            headers = {'content-type': 'application/json'}
            params = {'key': api_key}
            response = requests.post(api_url, json=settings_dict, headers=headers, params=params)
            if response.status_code == 200:
                # Write the updated settings to file
                write_settings_to_file(settings_dict)
                return jsonify({'message': 'Scanner settings updated successfully'}), 200
            else:
                error_msg = 'Failed to update scanner settings: %s' % response.content
                return jsonify({'error': error_msg}), 500
        else:
            return jsonify({'error': 'No settings provided'}), 400
    else:
        return jsonify({'error': 'API key not found'}), 500

if __name__ == '__main__':
    app.run(debug=True, port=8000)
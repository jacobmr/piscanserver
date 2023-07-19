from flask import Flask, render_template, request, jsonify, redirect, url_for
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
    mode = SelectField('Mode', choices=[('Lineart', 'Lineart'), ('Gray', 'Gray'), ('Color', 'Color')], validators=[DataRequired()])
    resolution = SelectField('Resolution', choices=[('75', '75'), ('100', '100'), ('150', '150'), ('200', '200'), ('300', '300'), ('600', '600'), ('1200', '1200')], validators=[DataRequired()])
    source = SelectField('Source', choices=[('Flatbed', 'Flatbed'), ('ADF', 'ADF'), ('Duplex', 'Duplex')], validators=[DataRequired()])
    brightness = SelectField('Brightness', choices=[(str(i), str(i)) for i in range(-1000, 1001)], validators=[DataRequired()])
    contrast = SelectField('Contrast', choices=[(str(i), str(i)) for i in range(-1000, 1001)], validators=[DataRequired()])
    compression = SelectField('Compression', choices=[('None', 'None'), ('JPEG', 'JPEG')], validators=[DataRequired()])
    jpeg_quality = SelectField('JPEG Quality', choices=[(str(i), str(i)) for i in range(101)], validators=[DataRequired()], default='50')
    errors = SelectField('Errors', choices=[('yes', 'yes'), ('no', 'no')], validators=[DataRequired()])
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
        mode=default_settings.get('MODE', 'Lineart'),
        resolution=default_settings.get('RESOLUTION', '75'),
        source=default_settings.get('SOURCE', 'Flatbed'),
        brightness=default_settings.get('BRIGHTNESS', '0'),
        contrast=default_settings.get('CONTRAST', '0'),
        compression=default_settings.get('COMPRESSION', 'JPEG'),
        jpeg_quality=default_settings.get('JPEG_QUALITY', '50'),
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
            "JPEG_QUALITY": form.jpeg_quality.data,
            "ERRORS": form.errors.data
        }
        write_settings_to_file(settings_dict)
        return redirect(url_for('index'))
    print(form.errors)
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
        if 'jpeg_quality' in request.args:
            settings_dict['JPEG_QUALITY'] = request.args.get('jpeg_quality')
        if 'errors' in request.args:
            settings_dict['ERRORS'] = request.args.get('errors')
        if settings_dict:
            api_url = 'http://scan.salundo.com/api/scanner'
            headers = {'content-type': 'application/json'}
            params = {'key': api_key}
            response = requests.post(api_url, json=settings_dict, headers=headers, params=params)
            if response.status_code == 200:
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

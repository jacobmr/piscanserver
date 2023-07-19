from flask import Flask, render_template, request
from flask_wtf import FlaskForm
from wtforms import SelectField, SubmitField
from wtforms.validators import DataRequired
from flask_bootstrap import Bootstrap
import os

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

@app.route('/', methods=['GET', 'POST'])
def index():
    form = SettingsForm(mode='Grayscale', resolution='300', source='ADF', brightness='0', contrast='0', compression='PNG', errors='Ignore')
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
        with open('config.txt', 'w') as file:
            file.writelines('%s=%s\n' % (key, value) for key, value in settings_dict.items())
    return render_template('index.html', form=form)

if __name__ == '__main__':
    app.run(debug=True, port=8000)
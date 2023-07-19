import os  # Add this import at the beginning of your script
from flask import Flask, render_template, request
from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField
from wtforms.validators import DataRequired
from flask_bootstrap import Bootstrap

app = Flask(__name__)
bootstrap = Bootstrap(app)  
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY')  # Loading the secret key from environment variable

class SettingsForm(FlaskForm):
    mode = StringField('Mode', validators=[DataRequired()])
    resolution = StringField('Resolution', validators=[DataRequired()])
    source = StringField('Source', validators=[DataRequired()])
    brightness = StringField('Brightness', validators=[DataRequired()])
    contrast = StringField('Contrast', validators=[DataRequired()])
    compression = StringField('Compression', validators=[DataRequired()])
    errors = StringField('Errors', validators=[DataRequired()])
    submit = SubmitField('Submit')

@app.route('/', methods=['GET', 'POST'])
def index():
    form = SettingsForm()
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
    return render_template('index.html', form=form, bootstrap=bootstrap) 

if __name__ == '__main__':
    app.run(debug=True, port=8000)

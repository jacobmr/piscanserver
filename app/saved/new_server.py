from flask import Flask
from flask_ask import Ask, statement

app = Flask(__name__)
ask = Ask(app, '/')

@ask.intent('scansomething')
def hello():
    return statement("Hello, scanner ready!")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)

from flask import Flask, request
#from flask_ask import Ask, statement
app = Flask(__name__)

@app.route('/')
def home():
    return "Hello, Alexa!"

@app.route('/alexa', methods=['POST'])
def alexa():
    # Here is where you will add the handling code for your Alexa skill.
    # For now, let's just print out the request.
    print(request.json)
    return "OK"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)


#@ask.intent('scansomething')
#def hello():
 #   return statement("Hello, scanner ready!")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)

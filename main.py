import os
from stdnet import odm
from user_controller import UserController
from flask import Flask, redirect, render_template, request, json, jsonify
from redis import Redis
from user import User

app = Flask(__name__)
app.debug = True

models = odm.Router('redis://127.0.0.1:6379')
models.register(User)

controllers = {
    'signup' : UserController,
    'signin' : UserController,
    'signout' : UserController
}

@app.route('/', methods = ["GET", "POST"])
def index():
    if request.method == "GET":
        return render_template('index.html')
    else:
        data = json.loads(str(request.json).replace("'", '"'))
        action = data['action']
        controller = controllers[action](data['params'], models)
        return getattr(controller, action)()

if __name__ == '__main__':
    app.run(host='0.0.0.0')
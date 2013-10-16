#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

from stdnet import odm
from controller import *
import json
from game_exception import GameException, UnknownAction
from common import *
from model import *
from tornado import ioloop, web, autoreload, websocket

models = odm.Router('redis://127.0.0.1:6379')

model_classes = [User, Message, Game, Map]
for model in model_classes:
    models.register(model)
    if hasattr(model, "pre_commit"):
        models.pre_commit.connect(getattr(model, "pre_commit"), sender=model)

def controller_by_action_hash(controllers):
    return {key: value for value in controllers for key in dir(value) if key.find("_")}

class ActionProcesser():
    def __init__(self, controllers):
        self.controllers = controllers
        self.controller_by_action = controller_by_action_hash(controllers)

    def process_action(self, action_name, data):
        try:
            controller = self.controller_by_action[action_name](data, models)
        except (KeyError, ValueError):
            return UnknownAction().msg()

        try:
            response = getattr(controller, action_name)()
            return response
        except GameException as e:
            return e.msg()


class MainWSHandler(websocket.WebSocketHandler):
    controllers = [GameplayController]

    processer = ActionProcesser(controllers)

    def on_message(self, message):
        data = message.decode("utf-8", "replace")

        try:
            data = json.loads(data)
            action = camel_to_underscores(str(data['action']))
            self.write_message(self.processer.process_action(action, data))
        except (KeyError, ValueError):
            self.write_message(UnknownAction().msg())
            return

class MainHandler(web.RequestHandler):
    """Main application requests handler"""

    controllers = [UserController, MessageController, GameController, MapController, CommonController]

    processer = ActionProcesser(controllers)

    def get(self):
        self.render("templates/spec_runner.html")

    def options(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "Content-Type, X-Requested-With")
        self.write("")

    def post(self):
        data = self.request.body.decode("utf-8", "replace")

        try:
            data = json.loads(data)
            action = camel_to_underscores(str(data['action']))
            self.write(self.processer.process_action(action, data['params']))
        except (KeyError, ValueError):
            self.write(UnknownAction().msg())
            return

if __name__ == '__main__':
    application = web.Application([
        (r'/static/(.*)', web.StaticFileHandler, {'path': 'static'}),
        (r"/", MainHandler),
        (r'/', MainWSHandler),
    ])
    application.listen(5000)
    ioloop = ioloop.IOLoop.instance()
    autoreload.start(ioloop)
    ioloop.start()
#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

from stdnet import odm
from controller import *
import json
from compile_coffee import CoffeeCompiler
from datetime import datetime
from game_exception import *
from common import *
from model import *
from current_games import CurrentGames
from tornado import ioloop, web, autoreload, websocket
import tornado.options

games = CurrentGames()

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
            try:
                controller = self.controller_by_action[action_name](data, models, games)
            except (KeyError, ValueError):
                raise BadAction()

            response = getattr(controller, action_name)()
            return response
        except GameException as e:
            return e.msg()

class MainWSHandler(websocket.WebSocketHandler):

    def open(self):
        print("opened")
        self.application.websockets.add(self)
        self.controller = None

    def tick(self):
        if self.controller:
            self.write_message(self.controller.tick())

    def on_message(self, message):
        # try:
        print(message)
        data = json.loads(message)
        self.controller = self.controller if self.controller else GameplayController(data['params'], models, games)
        self.controller.json = data['params']

        action = camel_to_underscores(str(data['action']))
        getattr(self.controller, action)()
        # except (KeyError, ValueError):
            # self.write_message(BadAction().msg())
            # return

    def on_close(self, message=None):
        print("closed")
        self.application.websockets.remove(self)

class MainHandler(web.RequestHandler):
    """Main application requests handler"""

    controllers = [UserController, MessageController, GameController, MapController, CommonController]

    processer = ActionProcesser(controllers)
    count = 0
    def get(self):
        self.render("templates/spec_runner.html")

    def options(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "Content-Type, X-Requested-With")
        self.write("")

    def post(self):
        data = self.request.body.decode("utf-8", "replace")
        print(data)
        try:
            data = json.loads(data)
        except (ValueError):
            self.write(BadJSON().msg())
            return

        try:
            action = camel_to_underscores(str(data['action']))
            self.write(self.processer.process_action(action, data.get("params", {})))
        except (KeyError, TypeError):
            self.write(BadRequest().msg())
            return

class DemoHandler(web.RequestHandler):

    def get(self):
        self.render("templates/demo.html")

    def options(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "Content-Type, X-Requested-With")
        self.write("")

class GameApp(web.Application):
    def __init__(self):
        self.websockets = set()

        handlers = [
            (r'/static/(.*)', web.StaticFileHandler, {'path': 'static'}),
            (r"/", MainHandler),
            (r'/websocket', MainWSHandler),
            (r'/demo', DemoHandler),
        ]

        super(GameApp, self).__init__(handlers)


    def tick(self):
        if len(self.websockets) == 0:
            return

        for game in games.games.values():
            if not game.next_tick(CommonController.WEBSOCKET_MODE_SYNC):
                return

        if CommonController.WEBSOCKET_MODE_SYNC:
            for game in games.games.values():
                game.update_players()

        print("tick")
        for sock in self.websockets:
            sock.tick()


CLIENT_SCRIPTS_DIR = "client"

if __name__ == '__main__':
    coffee_compiler = CoffeeCompiler(CLIENT_SCRIPTS_DIR)
    coffee_compiler.compile()

    application = GameApp()

    tornado.options.parse_command_line()

    application.listen(5000)
    loop = ioloop.IOLoop.instance()
    timer = ioloop.PeriodicCallback(application.tick, 30, io_loop = loop)
    autoreload.start(loop)

    timer.start()
    loop.start()

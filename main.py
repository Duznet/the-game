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


models = odm.Router('redis://127.0.0.1:6379')

model_classes = [User, Message, Game, Map, GameStat]
for model in model_classes:
    models.register(model)
    if hasattr(model, "pre_commit"):
        models.pre_commit.connect(getattr(model, "pre_commit"), sender=model)

games = CurrentGames()

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

        self.controller.join_game()

        action = camel_to_underscores(str(data['action']))
        getattr(self.controller, action)()
        # except (KeyError, ValueError):
            # self.write_message(BadAction().msg())
            # return

    def on_close(self, message=None):
        print("closed")
        if self.controller:
            self.controller.leave_game()
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
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "Content-Type, X-Requested-With")
        data = self.request.body.decode("utf-8", "replace")
        print(data)
        try:
            data = json.loads(data)
            print(data)
        except (ValueError):
            self.write(BadJSON().msg())
            return

        # try:
        action = camel_to_underscores(str(data['action']))
        response = self.processer.process_action(action, data.get("params", {}))
        print(response)
        self.write(response)
        # except (KeyError, TypeError):
        #     self.write(BadRequest().msg())
        #     print("badRequest")
        #     return

class DemoHandler(web.RequestHandler):

    def get(self):
        self.render("templates/demo.html")

    def options(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "Content-Type, X-Requested-With")
        self.write("")

class UIHandler(web.RequestHandler):

    def get(self):
        self.render("templates/index.html")

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
            (r'/ui', UIHandler),
        ]

        super(GameApp, self).__init__(handlers)


    def tick(self):
        for game in models.game.filter(status="running").all():
            if games.games.get(game.id) is None:
                game.clear()


        if len(self.websockets) == 0:
            return

        for game in games.games.values():
            if not game.next_tick(CommonController.WEBSOCKET_MODE_SYNC):
                return

        if CommonController.WEBSOCKET_MODE_SYNC:
            for game in games.games.values():
                game.update_players()

        # print("tick")
        for sock in self.websockets:
            sock.tick()


CLIENT_SCRIPTS_DIR = "client"

if __name__ == '__main__':

    tornado.options.define("port", default=5000, type=int, help="port")
    tornado.options.define("coffee_compile_off", default=False, type=bool, help="disable coffee script files compiling")
    tornado.options.parse_command_line()
    port = tornado.options.options.port

    if not tornado.options.options.coffee_compile_off:
        coffee_compiler = CoffeeCompiler(CLIENT_SCRIPTS_DIR)
        coffee_compiler.compile()

    application = GameApp()


    application.listen(port)
    loop = ioloop.IOLoop.instance()
    timer = ioloop.PeriodicCallback(application.tick, 30, io_loop = loop)
    autoreload.start(loop)

    timer.start()
    loop.start()

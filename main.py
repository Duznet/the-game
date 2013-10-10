import os
from stdnet import odm
from game_exception import GameException
from user_controller import UserController
from message_controller import MessageController
from game_controller import GameController
from map_controller import MapController
import json
import re
from redis import Redis
from user import User
from game import Game
from map import Map
from message import Message
from tornado import ioloop, web, autoreload

models = odm.Router('redis://127.0.0.1:6379')

model_classes = [User, Message, Game, Map]
for model in model_classes:
    models.register(model)
    if hasattr(model, "pre_commit"):
        models.pre_commit.connect(getattr(model, "pre_commit"), sender=model)

controllers = [UserController, MessageController, GameController, MapController]
controller_by_action = {key: value for value in controllers for key in dir(value) if key.find("_")}

def lower(matchobj):
    return "_" + matchobj.group(0).lower()

def camel_to_underscores(string):
    return re.sub(r'([A-Z])', lower, string)

class MainHandler(web.RequestHandler):
    """Main application requests handler"""

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
            controller = controller_by_action[action](data['params'], models)
        except (KeyError, ValueError):
            self.write('{"result" : "unknownAction"}')
            return

        try:
            self.write(getattr(controller, action)())
        except GameException as e:
            self.write(e.msg())


if __name__ == '__main__':
    application = web.Application([
        (r'/static/(.*)', web.StaticFileHandler, {'path': 'static'}),
        (r"/", MainHandler),
    ])
    application.listen(5000)
    ioloop = ioloop.IOLoop.instance()
    autoreload.start(ioloop)
    ioloop.start()
import os
from stdnet import odm
from game_exception import GameException
from user_controller import UserController
from message_controller import MessageController
import json
from redis import Redis
from user import User
from message import Message
from tornado import ioloop, web, autoreload

models = odm.Router('redis://127.0.0.1:6379')
models.register(User)
models.register(Message)

controllers = [UserController, MessageController]
controller_by_action = {key: value for value in controllers for key in dir(value)}

class MainHandler(web.RequestHandler):
    """Main application requests handler"""

    def get(self):
        self.render("templates/spec_runner.html")

    def post(self):
        data = self.request.body.decode("utf-8", "replace")

        try:
            data = json.loads((data))
            action = data['action']
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
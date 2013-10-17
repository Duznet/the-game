from common import jsonify
from datetime import datetime
from controller.basic_controller import BasicController
from game_exception import BadSince, BadGame

class MessageController(BasicController):
    """Controller for messages"""
    def __init__(self, json, models, games):
        super(MessageController, self).__init__(json, models.user)
        self.messages = models.message

    def get_messages(self):
        self.user
        all_messages = self.messages.filter(game = self.user.game) if str(self.json['game']) else self.messages.all()
        if str(self.json['game']):
            try:
                game_id = int(str(self.json['game']))

                if game_id != self.user.game.id():
                    raise BadGame()

            except ValueError:
                raise BadGame()

        try:
            since = float(str(self.json['since']))
        except ValueError:
            raise BadSince()

        messages = [msg for msg in all_messages if msg.timestamp >= since]


        return jsonify(
            result="ok",
            messages=[{ "time": msg.timestamp, "text": msg.text, "login": msg.user.login} for msg in messages])
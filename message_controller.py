import json
from datetime import datetime
from basic_controller import BasicController
from game_exception import BadTimestamp

class MessageController(BasicController):
    """Controller for messages"""
    def __init__(self, json, models):
        super(MessageController, self).__init__(json)
        self.messages = models.message
        self.users = models.user

    def getMessages(self):
        user = self.user_by_sid()
        all_messages = self.messages.filter(game = user.game)

        try:
            since = float(self.json['since'])
        except ValueError:
            raise BadTimestamp()

        messages = [msg for msg in all_messages if msg.timestamp >= since]


        return json.dumps({"result": "ok", "messages": [{ "time": msg.timestamp, "text": msg.text, "login": msg.user.login} for msg in messages]})
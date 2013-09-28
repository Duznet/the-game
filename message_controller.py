import json
from datetime import datetime
from basic_controller import BasicController

class MessageController(BasicController):
    """Controller for messages"""
    def __init__(self, json, models):
        super(MessageController, self).__init__(json)
        self.messages = models.message

    def getMessages(self):
        all_messages = self.messages.all()
        messages = []
        for msg in all_messages:
            if msg.timestamp >= self.json['since']:
                messages.append(msg)

        return json.dumps({"result": "ok", "messages": [{ "time": msg.timestamp, "text": msg.text, "login": msg.user.login} for msg in messages]})
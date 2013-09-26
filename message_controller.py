import json
from datetime import datetime
from basic_controller import BasicController

class MessageController(BasicController):
    """Controller for messages"""
    def __init__(self, json, models):
        super(MessageController, self).__init__()
        self.messages = models.message

    def getMessages(self):
        timestamp = datetime(json['since'])
        messages = self.messages.filter(timestamp__ge = timestamp)
        return json.dumps([{ "time": msg.timestamp, "text": msg.text, "login": msg.user.login} for msg in messages.items()])
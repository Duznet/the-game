from flask import jsonify
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
        return jsonify(map((lambda x: { "time" : x.timestamp, "text" : x.text, "login" : x.user.login}), messages.items()))
from basic_controller import BasicController
from datetime import datetime
from stdnet.utils.exceptions import CommitException
import json

class UserController(BasicController):
    """Controller for creating and authenticating users"""
    def __init__(self, json, models):
        super(UserController, self).__init__(json)
        self.users = models.user

    def signup(self):
        try:
            self.users.new(login = self.json['login'], password = self.json['password'])
        except CommitException:
            return json.dumps({"result" : "userExists"})
        return json.dumps({"result" : "ok"})

    def signin(self):
        user = self.users.filter(login = self.json['login'], password = self.json['password'])
        if user.count() == 1:
            user = user.items()[0]
            user.sid = user.login + user.password + str(datetime.now())
            user.save
            return json.dumps({"result" : "ok", "sid" : user.sid})
        else:
            return json.dumps({"result" : "incorrect"})

    def signout(self):
        user = self.users.filter(sid = self.json['sid'])
        if user.count() == 1:
            user = user.items()[0]
            user.sid = ""
            user.save
            return json.dumps({"result" : "ok"})
        else:
            return json.dumps({"result" : "badSid"})

    def sendMessage(self):
        user = self.users.filter(sid = self.json['sid'])
        if user.count() == 1:
            user = user.items()[0]
            user.new_message(self.json['text'])
            return json.dumps({"result" : "ok"})
        else:
            return json.dumps({"result" : "badSid"})
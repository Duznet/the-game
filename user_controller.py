from basic_controller import BasicController
from datetime import datetime
from stdnet.utils.exceptions import CommitException
from flask import jsonify

class UserController(BasicController):
    """Controller for creating and authenticating users"""
    def __init__(self, json, models):
        super(UserController, self).__init__(json)
        self.users = models.user

    def signup(self):
        try:
            self.users.new(login = self.json['login'], password = self.json['password'], sid = 'asda')
        except CommitException:
            return jsonify({"result" : "userExists"})
        return jsonify({"result" : "ok"})

    def signin(self):
        user = self.users.filter(login = self.json['login'], password = self.json['password'])
        if user.count() == 1:
            user = user.items()[0]
            user.sid = user.login + user.password + str(datetime.now())
            user.save
            return jsonify({"result" : "ok", "sid" : user.sid})
        else:
            return jsonify({"result" : "incorrect"})

    def signout(self):
        user = self.users.filter(sid = self.json['sid'])
        if user.count() == 1:
            user = user.items()[0]
            user.sid = ""
            user.save
            return jsonify({"result" : "ok"})
        else:
            return jsonify({"result" : "badSid"})
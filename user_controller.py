from basic_controller import BasicController
from datetime import datetime
from stdnet.utils.exceptions import CommitException
from game_exception import *
from game import Game
import json

class UserController(BasicController):
    """Controller for creating and authenticating users"""
    MIN_LOGIN_SYMBOLS = 4
    MAX_LOGIN_SYMBOLS = 40
    MIN_PASSWORD_SYMBOLS = 4

    def __init__(self, json, models):
        super(UserController, self).__init__(json)
        self.users = models.user

    def signup(self):
        try:
            if len(self.json['login']) < self.MIN_LOGIN_SYMBOLS or len(self.json['login']) > self.MAX_LOGIN_SYMBOLS:
                raise BadLogin()

            if len(self.json['password']) < self.MIN_PASSWORD_SYMBOLS:
                raise BadPassword()

            self.users.new(login = self.json['login'], password = self.json['password'])
        except CommitException:
            raise UserExists()

        return json.dumps({"result" : "ok"})

    def signin(self):
        try:
            user = self.users.filter(login = self.json['login'], password = self.json['password'])
        except KeyError:
            raise Incorrect()

        if user.count() != 1:
            raise Incorrect()
        user = user.items()[0]
        user.sid = user.login + user.password + str(datetime.now())
        user.save()
        return json.dumps({"result" : "ok", "sid" : user.sid})

    def signout(self):
        user = self.user_by_sid()
        user.sid = ''
        user.save
        return json.dumps({"result" : "ok"})

    def sendMessage(self):
        user = self.user_by_sid()
        user.new_message(self.json['text'])
        return json.dumps({"result" : "ok"})

    def joinGame(self):
        user = self.user_by_sid()
        user.join_game(id = self.json['id'])
        return json.dumps({"result" : "ok"})

    def leaveGame(self):
        user = self.user_by_sid()
        user.leave_game(self.json['id'])
        return json.dumps({"result" : "ok"})
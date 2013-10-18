from controller.basic_controller import BasicController
from datetime import datetime
from stdnet.utils.exceptions import CommitException
from game_exception import Incorrect, UserExists, BadPassword
from common import jsonify
import hashlib

class UserController(BasicController):
    """Controller for creating and authenticating users"""

    MIN_PASSWORD_SYMBOLS = 4

    def __init__(self, json, models, games):
        super(UserController, self).__init__(json)
        self.users = models.user
        self.messages = models.message
        self.games = models.game
        self.current_games = games

    def signup(self):
        try:
            if len(str(self.json['password'])) < self.MIN_PASSWORD_SYMBOLS:
                raise BadPassword()

            self.users.new(login=str(self.json['login']), password=self.users.encode(str(self.json['password'])))
        except CommitException:
            raise UserExists()

        return jsonify(result="ok")

    def signin(self):
        try:
            user = self.users.filter(login=str(self.json['login']), password=self.users.encode(str(self.json['password'])))
        except KeyError:
            raise Incorrect()

        if user.count() != 1:
            raise Incorrect()
        user = user.items()[0]
        return jsonify(result="ok", sid=user.authenticate())

    def signout(self):
        user = self._user_by_sid()
        user.signout()
        return jsonify(result="ok")

    def send_message(self):
        user = self._user_by_sid()
        user.new_message(str(self.json['text']), str(self.json['game']), self.messages)
        return jsonify(result="ok")

    def join_game(self):
        user = self._user_by_sid()
        user.join_game(id=str(self.json['game']))
        self.current_games.game(int(self.json['game'])).add_player(user.id)
        return jsonify(result="ok")

    def leave_game(self):
        user = self._user_by_sid()
        user.leave_game()
        return jsonify(result="ok")
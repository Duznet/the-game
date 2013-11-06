from controller.basic_controller import BasicController
from datetime import datetime
from stdnet.utils.exceptions import CommitException
from game_exception import *
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
        user = self.users.filter(login=str(self.json['login']), password=self.users.encode(str(self.json['password'])))

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

        if not isinstance(self.json['text'], type("")):
            raise BadText()

        user.new_message(self.json['text'], str(self.json['game']), self.messages)
        return jsonify(result="ok")

    def join_game(self):
        user = self._user_by_sid()
        user.join_game(id=str(self.json['game']))
        self.current_games.game(int(self.json['game'])).add_player(user.id)
        return jsonify(result="ok")

    def leave_game(self):
        user = self._user_by_sid()
        if user.game:
            self.current_games.game(user.game.id).remove_player(user.id)
            if self.current_games.game(user.game.id).players_count() == 0:
                self.current_games.remove_game(user.game.id)
        user.leave_game()
        return jsonify(result="ok")

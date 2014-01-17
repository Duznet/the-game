from stdnet import odm
from re import match
from stdnet.utils.exceptions import CommitException, ObjectNotFound
from model.game import Game
from datetime import datetime
from game_exception import *
import hashlib
from datetime import datetime
from calendar import timegm


class User(odm.StdModel):
    """User model"""

    MIN_LOGIN_SYMBOLS = 4
    MAX_LOGIN_SYMBOLS = 40

    login = odm.SymbolField(unique=True)
    password = odm.SymbolField()
    sid = odm.SymbolField(index=True, required=False)
    game = odm.ForeignKey(Game, index=True, required=False, related_name="players")

    @staticmethod
    def encode(password):
        return hashlib.sha1(password.encode("utf-8")).hexdigest()

    def authenticate(self):
        self.sid = self.encode(self.login + self.password + str(datetime.now().timestamp()))
        self.save()
        return self.sid

    def signout(self):
        self.sid = ''
        self.save()

    def new_message(self, text, game_id, message):
        try:
            if len(game_id) == 0:
                return message.new(text=text, timestamp=datetime.utcnow().timestamp(), user=self)

            if self.game is None or str(self.game.id) != str(game_id):
                raise BadGame()

            return message.new(text=text, timestamp=datetime.utcnow().timestamp(), user=self, game=self.game)

        except (ValueError, ObjectNotFound):
            raise BadGame()

    def join_game(self, id):

        try:
            game = self.session.query(Game).get(id = id)
        except:
            raise BadGame()

        # if not game:
        #     raise BadGame()

        if self.game:
            raise AlreadyInGame()

        if len(game.players.all()) == game.max_players:
            raise GameFull()

        self.game = game
        self.save()
        return game

    def leave_game(self):
        if not self.game:
            raise NotInGame()

        # if len(self.game.players.all()) < 2:
        #     self.game.delete()

        self.game = None
        self.save()
        return self

    def is_login_correct(login):
        return len(login) < User.MIN_LOGIN_SYMBOLS or len(login) > User.MAX_LOGIN_SYMBOLS

    def pre_commit(instances, **named):
        user = instances[0]
        if User.is_login_correct(user.login):
            raise BadLogin()

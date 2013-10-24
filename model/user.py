from stdnet import odm
from re import match
from stdnet.utils.exceptions import CommitException, ObjectNotFound
from model.game import Game
from datetime import datetime
from game_exception import *
import hashlib
from datetime import datetime

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

            game = self.session.query(Game).get(id=int(game_id))
            return message.new(text=text, timestamp=datetime.utcnow().timestamp(), user=self, game=game)
        except (ValueError, ObjectNotFound):
            raise BadGame()

    def join_game(self, id):
        game = self.session.query(Game).filter(id = id)
        if game.count() != 1:
            raise BadGame()

        if self.game:
            raise AlreadyInGame()

        game = game.items()[0]

        if len(game.players.all()) == game.max_players:
            raise GameFull()

        self.game = game
        self.save()
        return game

    def leave_game(self):
        if not self.game:
            raise NotInGame()

        if len(self.game.players.all()) < 2:
            self.game.delete()

        self.game = None
        self.save()
        return self

    def pre_commit(instances, **named):
        user = instances[0]
        if len(user.login) < user.MIN_LOGIN_SYMBOLS or len(user.login) > user.MAX_LOGIN_SYMBOLS:
            raise BadLogin()

from stdnet import odm
from game import Game
from datetime import datetime
from game_exception import BadGameId

class User(odm.StdModel):
    """User model"""

    login = odm.SymbolField(unique = True)
    password = odm.SymbolField()
    sid = odm.SymbolField(index = True, required = False)
    game = odm.ForeignKey(Game, index = True, required = False, related_name = "users")

    def new_message(self, text, game_id, message):
        try:
            if len(game_id) == 0:
                return message.new(text = text, timestamp = datetime.utcnow().timestamp(), user = self)

            game = odm.session.query(Game).filter(id = int(game_id))
            return message.new(text = text, timestamp = datetime.utcnow().timestamp(), user = self, game = game)
        except ValueError:
            raise BadGameId()

    def join_game(self, id):
        game = odm.session.query(Game).filter(id = id)
        if game.count() != 1:
            raise BadGameId()
        game = game.items()[0]

        self.game = game
        self.save()
        return game

    def leave_game(self, id):
        game = odm.session.query(Game).filter(id = id)
        if game.count() != 1:
            raise BadGameId()

        game.delete()
        self.save()
        return self
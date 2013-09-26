from stdnet import odm
from message import Message
from game import Game

class User(odm.StdModel):
    """User model"""

    login = odm.SymbolField(unique = True)
    password = odm.SymbolField()
    sid = odm.SymbolField(index = True, required = False)

    def new_message(self, text):
        return Message(text = text, user = self).save()

    def new_game(self, map, name, max_players):
        return Game(map = map, name = name, max_players = max_players).save()
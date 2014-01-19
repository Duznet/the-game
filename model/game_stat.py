from stdnet import odm
from stdnet.utils.exceptions import CommitException
from model.game import Game

class GameStat(odm.StdModel):
    """GameStat model"""

    MIN_NAME_LENGTH = 1

    login = odm.SymbolField()
    kills = odm.IntegerField()
    deaths = odm.IntegerField()

    game = odm.ForeignKey(Game, index=True, required=True, related_name="player_stats")


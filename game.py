from stdnet import odm
from stdnet.utils.exceptions import CommitException
from map import Map
from game_exception import BadMaxPlayers, BadMapName, BadGameName

class Game(odm.StdModel):
    """Game model"""

    name = odm.SymbolField(unique = True)
    map = odm.ForeignKey(Map, required = True, index = True, related_name = 'games')
    max_players = odm.IntegerField()
    status = odm.SymbolField(default = "started")

    def pre_commit(instances, **named):
        game = instances[0]
        if game.map.max_players() < game.max_players():
            raise BadMaxPlayers()


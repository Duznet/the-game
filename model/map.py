from stdnet import odm
from stdnet.utils.exceptions import CommitException
from game_exception import BadMapName

class Map(odm.StdModel):
    """Model for map"""

    name = odm.SymbolField(unique=True)
    map = odm.JSONField()
    max_players = odm.IntegerField()

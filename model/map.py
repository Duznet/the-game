from stdnet import odm
from stdnet.utils.exceptions import CommitException
from game_exception import BadName, BadMap

class Map(odm.StdModel):
    """Model for map"""

    name = odm.SymbolField(unique=True)
    map = odm.JSONField()
    max_players = odm.IntegerField()

    @staticmethod
    def is_map_valid(map):
        if not len(map):
            return False

        size = len(map[0])

        for string in map:
            if len(string) != size:
                return False

        return True

    def pre_commit(instances, **named):
        map = instances[0]

        if not map.name:
            raise BadName

        if not map.is_map_valid(list(map.map)):
            raise BadMap



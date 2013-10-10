from basic_controller import BasicController
from game_exception import BadMapName, BadMaxPlayers
from stdnet import odm
from stdnet.utils.exceptions import CommitException
import json

class MapController(BasicController):
    """Controller for all actions with maps"""

    def __init__(self, json, models):
        super(MapController, self).__init__(json)
        self.maps = models.map

    def upload_map(self):
        try:
            self.maps.new(
                name = str(self.json['name']),
                map = str(self.json['map']),
                max_players = int(str(self.json['maxPlayers'])))
        except CommitException:
            raise BadMapName()
        except ValueError:
            raise BadMaxPlayers()

        return '{"result" : "ok"}'



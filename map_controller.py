from basic_controller import BasicController
from game_exception import BadMapName, BadMaxPlayers
from stdnet import odm
from stdnet.utils.exceptions import CommitException
from common import jsonify

class MapController(BasicController):
    """Controller for all actions with maps"""

    def __init__(self, json, models):
        super(MapController, self).__init__(json)
        self.maps = models.map
        self.users = models.user

    def get_maps(self):
        maps = self.maps.all()
        return jsonify([{
            "id": map.id,
            "name": map.name,
            "map": map.map,
            "maxPlayers": map.max_players,
            } for map in maps])

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

        return jsonify(result = "ok")



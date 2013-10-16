from controller.basic_controller import BasicController
from stdnet import odm
from stdnet.utils.exceptions import CommitException
from game_exception import *
from common import jsonify

class GameController(BasicController):
    """Controller for all actions with games"""

    def __init__(self, json, models):
        super(GameController, self).__init__(json)
        self.games = models.game
        self.maps = models.map
        self.users = models.user

    def create_game(self):
        user = self._user_by_sid()

        if user.game:
            raise AlreadyInGame()

        try:
            maps = self.maps.filter(id = str(self.json['map']))
            if maps.count() != 1:
                raise BadMapName()

            map = maps[0]
            game = self.games.new(map = map, name =  str(self.json['name']), max_players = int(str(self.json['maxPlayers'])))
            user.game = game
            user.save()
        except CommitException:
            raise GameExists()
        except ValueError:
            raise BadMaxPlayers()
        return jsonify(result="ok")

    def get_games(self):
        games = self.games.all()
        return jsonify(
            games=[{
                "name": game.name,
                "id": game.id,
                "map": game.map,
                "maxPlayers": game.max_players,
                "players": game.users.count(),
                "status": game.status
                } for game in games],
            result="ok")


from controller.basic_controller import BasicController
from stdnet import odm
from stdnet.utils.exceptions import CommitException
from game_exception import *
from common import jsonify

class GameController(BasicController):
    """Controller for all actions with games"""

    def __init__(self, json, models, games):
        super(GameController, self).__init__(json, models.user)
        self.games = models.game
        self.maps = models.map
        self.current_games = games

    def create_game(self):
        if self.user.game:
            raise AlreadyInGame()

        try:
            map = self.maps.get(id=int(self.json['map']))
        except ValueError:
            raise BadMap()

        if not map:
            raise BadMap()

        try:
            game = self.games.new(map = map, name =  str(self.json['name']), max_players = int(str(self.json['maxPlayers'])))
            self.user.game = game
            self.user.save()
            self.current_games.add_game(game.id, map.map).add_player(self.user.id)
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
                "map": list(game.map.map),
                "maxPlayers": game.max_players,
                "players": [self.users.get(id=id).login for id in self.current_games.game(game.id).player_ids()],
                "status": game.status
                } for game in games],
            result="ok")


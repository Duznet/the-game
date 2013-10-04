from basic_controller import BasicController
from stdnet import odm
from stdnet.utils.exceptions import CommitException
from game_exception import *
import json

class GameController(BasicController):
    """Controller for all actions with games"""

    def __init__(self, json, models):
        super(GameController, self).__init__(json)
        self.games = models.game
        self.maps = models.map
        self.users = models.user

    def createGame(self):
        user = self._user_by_sid()

        if user.game:
            raise AlreadyInGame()

        try:
            maps = self.maps.filter(name = str(self.json['map']))
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
        return json.dumps({"result" : "ok"})

    def getGames(self):
        games = self.games.all()
        return json.dumps([{
            "name": game.name,
            "id": game.id,
            "map": game.map,
            "maxPlayers": game.max_players,
            "players": game.users.count(),
            "status": game.status
            } for game in games])


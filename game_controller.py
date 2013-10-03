from basic_controller import BasicController
import json

class GameController(BasicController):
    """Controller for all actions with games"""

    def __init__(self, json, models):
        super(GameController, self).__init__(json)
        self.games = models.game

    def createGame(self):
        user = self._user_by_sid()
        games.new(map = str(self.json['map']), name =  str(self.json['name']), max_players = str(self.json['maxPlayers']))
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


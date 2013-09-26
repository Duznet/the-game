from basic_controller import BasicController
class GameController(BasicController):
    """Controller for all actions with games"""

    def __init__(self, json, models):
        super(GameController, self).__init__(json)
        self.games = modes.game

    def createGame(self):
        user = self.user_by_sid()
        games.new(map = self.json['map'], name =  self.json['name'], max_players = self.json['maxPlayers'])
        return json.dumps({"result" : "ok"})

    def getMessages(self):
        games = self.games.all()
        return json.dumps([{
            "name": game.name,
            "id": game.id,
            "map": game.map,
            "maxPlayers": game.max_players,
            "players": game.users.count(),
            "status": game.status
            } for game in games.items()])


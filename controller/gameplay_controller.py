from controller.basic_controller import BasicController
from common import *

class GameplayController(BasicController):
    """Controller for gameplay actions"""

    def __init__(self, json, models, games):
        super(GameplayController, self).__init__(json, models.user)
        self.games = games


    def move():
        data = json['move']
        dx, dy = data['dx'], data['dy']

        game = games.game(self.user.game.id)
        game.move(self.user.id, dx, dy)

        return jsonify(players=game.players())
from controller.basic_controller import BasicController
from common import *

class GameplayController(BasicController):
    """Controller for gameplay actions"""

    def __init__(self, json, models, games):
        super(GameplayController, self).__init__(json, models.user)
        self.game = games.game(self.user.game.id)


    def move():
        data = json['move']
        dx, dy = data['dx'], data['dy']

        self.game.move(self.user.id, dx, dy)


    def tick():
        return jsonify(self.game.players())
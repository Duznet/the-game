from controller.basic_controller import BasicController
from common import *

class GameplayController(BasicController):
    """Controller for gameplay actions"""

    def __init__(self, json, models, games):
        super(GameplayController, self).__init__(json, models.user)
        self.game = games.game(self.user.game.id)


    def move(self):
        tick = int(self.json['tick'])
        print("game tick: " + str(self.game.tick) + ", tick got: " + str(tick))
        # if tick != self.game.tick:
        #     return

        dx, dy = self.json['dx'], self.json['dy']

        print("move ", dx, " ", dy)
        self.game.update_v(self.user.id, dx, dy)


    def tick(self):
        return jsonify(players=self.game.players(), tick=self.game.tick)
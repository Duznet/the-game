from controller.basic_controller import BasicController
from common import *

class GameplayController(BasicController):
    """Controller for gameplay actions"""

    def __init__(self, json, models, games):
        super(GameplayController, self).__init__(json, models.user)
        self.game = games.game(self.user.game.id)

    def empty(self):
        self.game.update_v(self.user.id, 0, 0).got_action = True

    def fire(self):
        dx, dy = self.json['dx'], self.json['dy']
        self.game.fire(self.user.id, dx, dy).got_action = True

    def move(self):
        tick = int(self.json['tick'])
        print("game tick: " + str(self.game.tick) + ", tick got: " + str(tick))
        # if tick != self.game.tick:
        #     return

        dx, dy = self.json['dx'], self.json['dy']

        print("move ", dx, " ", dy)
        self.game.update_v(self.user.id, dx, dy).got_action = True


    def tick(self):
        # print("projectiles", [proj.to_array() for proj in self.game.projectiles])
        return jsonify(
            players=self.game.players(),
            items=self.game.items,
            projectiles=[proj.to_array() for proj in self.game.projectiles],
            tick=self.game.tick)
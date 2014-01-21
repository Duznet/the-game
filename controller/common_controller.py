from controller.basic_controller import BasicController
from common import jsonify

class CommonController(BasicController):
    """Controller for some actions"""

    WEBSOCKET_MODE_SYNC = False

    def __init__(self, json, models, games):
        super(CommonController, self).__init__(json)
        self.models = models
        self.games = games

    def start_testing(self):
        self.models.flush()
        self.games.flush()

        CommonController.WEBSOCKET_MODE_SYNC = True if self.json.get("websocketMode") == "sync" else False
        print("websocketMode: ", self.json["websocketMode"])

        return jsonify(result="ok")

    def get_game_consts(self):
        return jsonify(result="ok", tickSize=30, accuracy=1e-6, accel=0.02, maxVelocity=0.4, gravity=0.02, friction=0.02)

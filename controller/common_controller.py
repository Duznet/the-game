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

        self.WEBSOCKET_MODE_SYNC = True if self.json.get("websocketMode") == "sync" else False

        return jsonify(result="ok")

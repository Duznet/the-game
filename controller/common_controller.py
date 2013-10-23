from controller.basic_controller import BasicController
from common import jsonify

class CommonController(BasicController):
    """Controller for some actions"""

    def __init__(self, json, models, games):
        super(CommonController, self).__init__(json)
        self.models = models
        self.games = games

    def start_testing(self):
        self.models.flush()
        self.games.flush()
        return jsonify(result="ok")

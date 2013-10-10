from basic_controller import BasicController

class CommonController(BasicController):
    """Controller for some actions"""

    def __init__(self, json, models):
        super(CommonController, self).__init__(json)
        self.models = models

    def start_testing(self):
        self.models.flush()
        return '{"result": "ok"}'

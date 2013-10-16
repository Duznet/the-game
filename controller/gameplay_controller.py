from controller.basic_controller import BasicController

class GameplayController(BasicController):
    """Controller for gameplay actions"""

    def __init__(self, json, models):
        super(GameplayController, self).__init__(json)
        self.users = models.user


class GameController(BasicController):
    """Controller for all actions with games"""

    def __init__(self, json, models):
        super(GameController, self).__init__(json)
        self.users = models.user
        self.games = modes.game

    def createGame(self):

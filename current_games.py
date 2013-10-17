from engine import Game

class CurrentGames:
    """Class to store information about current game processes"""

    games = {}

    def add_game(self, id, map):
        self.games[id] = Game(map)
        return games[id]

    def game(self, id):
        return self.games[id]
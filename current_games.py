from engine import Game

class CurrentGames:
    """Class to store information about current game processes"""

    games = {}

    def add_game(self, id, map):
        if id in self.games:
            print("what")
        self.games[id] = Game(map)
        return self.games[id]

    def remove_game(self, id):
        self.games.pop(id)

    def game(self, id):
        return self.games[id]

    def flush(self):
        self.games.clear()
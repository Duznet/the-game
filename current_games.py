from engine import Game

class CurrentGames:
    """Class to store information about current game processes"""

    games = {}

    def add_game(self, id, map, consts=None):
        if id in self.games:
            print("what")
        if consts:
            self.games[id] = Game(map,
                accel=float(consts['accel']),
                maxv=float(consts['maxVelocity']),
                friction=float(consts['friction']),
                gravity=float(consts['gravity']))
        else:
            self.games[id] = Game(map)
        return self.games[id]

    def remove_game(self, id):
        if self.game(id):
            self.games.pop(id)

    def game(self, id):
        return self.games.get(id)

    def flush(self):
        self.games.clear()
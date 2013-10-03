class GameException(Exception):
    """Base class for all exceptoins in webgame""",

    def msg(self):
        return ""


class BadLogin(GameException):
    """Login is incorrect"""

    def msg(self):
        return '{"result" : "badLogin"}'


class BadPassword(GameException):
    """Password is incorrect"""

    def msg(self):
        return '{"result" : "badPassword"}'


class UserExists(GameException):
    """User already exists"""

    def msg(self):
        return '{"result" : "userExists"}'


class BadSid(GameException):
    """There is no user with this sid"""

    def msg(self):
        return '{"result" : "badSid"}'



class Incorrect(GameException):
    """Data is incorrect"""

    def msg(self):
        return '{"result" : "incorrect"}'


class BadGame(GameException):
    """There is no game with this id"""

    def msg(self):
        return '{"result" : "badGame"}'

class BadGameName(GameException):
    """Game name is incorrect"""

    def msg(self):
        return '{"result" : "badName"}'

class BadMapName(GameException):
    """Map name is incorrect"""

    def msg(self):
        return '{"result" : "badMap"}'

class BadMaxPlayers(GameException):
    """Maximum players count is incorrect"""

    def msg(self):
        return '{"result" : "badMaxPlayers"}'

class GameExists(GameException):
    """Game already exists"""

    def msg(self):
        return '{"result" : "gameExists"}'

class AlreadyInGame(GameException):
    """User is already in game"""

    def msg(self):
        return '{"result" : "AlreadyInGame"}'

class GameFull(GameException):
    """Game is full"""

    def msg(self):
        return '{"result" : "gameFull"}'

class NotInGame(GameException):
    """User is not in game"""

    def msg(self):
        return '{"result" : "notInGame"}'


class BadSince(GameException):
    """Timestamp is uncorrect"""

    def msg(self):
        return '{"result" : "badSince"}'

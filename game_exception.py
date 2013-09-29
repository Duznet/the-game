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


class BadGameId(GameException):
    """There is no game with this id"""

    def msg(self):
        return '{"result" : "badGameId"}'


class BadTimestamp(GameException):
    """Timestamp is uncorrect"""

    def msg(self):
        return '{"result" : "badTimestamp"}'
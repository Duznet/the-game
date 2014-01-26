from common import jsonify

class GameException(Exception):
    """Base class for all exceptoins in webgame""",

    def msg(self):
        return ""


class BadLogin(GameException):
    """Login is incorrect"""

    def msg(self):
        return jsonify(result="badLogin")


class BadPassword(GameException):
    """Password is incorrect"""

    def msg(self):
        return jsonify(result="badPassword")


class UserExists(GameException):
    """User already exists"""

    def msg(self):
        return jsonify(result="userExists")


class BadSid(GameException):
    """There is no user with this sid"""

    def msg(self):
        return jsonify(result="badSid")



class Incorrect(GameException):
    """Data is incorrect"""

    def msg(self):
        return jsonify(result="incorrect")


class BadText(GameException):
    """Text is incorrect"""

    def msg(self):
        return jsonify(result="badText")


class BadGame(GameException):
    """There is no game with this id"""

    def msg(self):
        return jsonify(result="badGame")

class BadGameName(GameException):
    """Game name is incorrect"""

    def msg(self):
        return jsonify(result="badName")

class BadMapName(GameException):
    """Map name is incorrect"""

    def msg(self):
        return jsonify(result="badMap")

class BadMaxPlayers(GameException):
    """Maximum players count is incorrect"""

    def msg(self):
        return jsonify(result="badMaxPlayers")

class GameExists(GameException):
    """Game already exists"""

    def msg(self):
        return jsonify(result="gameExists")

class AlreadyInGame(GameException):
    """User is already in game"""

    def msg(self):
        return jsonify(result="alreadyInGame")

class GameFull(GameException):
    """Game is full"""

    def msg(self):
        return jsonify(result="gameFull")

class NotInGame(GameException):
    """User is not in game"""

    def msg(self):
        return jsonify(result="notInGame")


class BadSince(GameException):
    """Timestamp is uncorrect"""

    def msg(self):
        return jsonify(result="badSince")

class BadAction(GameException):
    """There is no such an action"""

    def msg(self):
        return jsonify(result="badAction")


class BadName(GameException):
    """Name is incorrect"""

    def msg(self):
        return jsonify(result="badName")


class BadMap(GameException):
    """Map data is incorrect"""

    def msg(self):
        return jsonify(result="badMap")

class MapExists(GameException):
    """Map already exists"""

    def msg(self):
        return jsonify(result="mapExists")

class BadJSON(GameException):
    """JSON object is incorrect"""

    def msg(self):
        return jsonify(result="badJSON")


class BadRequest(GameException):
    """Some paramater is missing"""

    def msg(self):
        return jsonify(result="badRequest")

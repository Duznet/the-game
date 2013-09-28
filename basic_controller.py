from game_exception import BadSid

class BasicController:
    """Controller base class"""
    def __init__(self, json):
        self.json = json

    def user_by_sid(self):
        try:
            user = self.users.filter(sid = self.json['sid'])
        except KeyError:
            raise BadSid()

        if user.count() != 1:
            raise BadSid()

        return user.items()[0]

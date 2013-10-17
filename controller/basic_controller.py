from game_exception import BadSid

class BasicController:
    """Controller base class"""

    def __init__(self, json, users=None):
        self.json = json
        if users:
            self.users = users
            self._user_by_sid()

    def _user_by_sid(self):
        try:
            user = self.users.filter(sid = str(self.json['sid']))
        except KeyError:
            raise BadSid()

        if user.count() != 1:
            raise BadSid()

        return user.items()[0]

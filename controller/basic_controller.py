from game_exception import *

class BasicController:
    """Controller base class"""

    def __init__(self, json, users=None):
        self.json = json
        if users:
            self.users = users
            self.user = self._user_by_sid()

    def _user_by_sid(self):
        try:
            user = self.users.filter(sid = str(self.json['sid']))
        except KeyError:
            raise BadRequest()

        if user.count() != 1:
            raise BadSid()

        return user.items()[0]


    def _str_param(self, name):
        if not isinstance(self.json[name], str):
            exception_classname = "Bad" + name[0].upper() + name[1:]
            raise globals()[exception_classname]()

        return self.json[name]
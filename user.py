from stdnet import odm
from message import Message

class User(odm.StdModel):
    """User model"""

    login = odm.SymbolField(unique = True)
    password = odm.SymbolField()
    sid = odm.CharField(default = '')

    def new_message(self, text):
        return Message(text = text, user = self).save()
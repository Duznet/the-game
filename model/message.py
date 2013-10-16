from stdnet import odm
from datetime import datetime
from model.user import User
from model.game import Game

class Message(odm.StdModel):
    """Message model"""

    text = odm.CharField()
    timestamp = odm.FloatField(index = True, required = True)
    user = odm.ForeignKey(User)
    game = odm.ForeignKey(Game, required = False)

    class Meta:
        ordering = "timestamp"

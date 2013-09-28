from stdnet import odm
from datetime import datetime
from user import User

class Message(odm.StdModel):
    """Message model"""

    text = odm.CharField()
    timestamp = odm.FloatField(index = True, required = True)
    user = odm.ForeignKey(User)

    class Meta:
        ordering = "timestamp"

from stdnet import odm
from datetime import datetime

class Message(odm.StdModel):
    """Message model"""

    text = odm.CharField()
    timestamp = odm.DateTimeField(default = datetime.now)
    user = odm.ForeignKey('User')

    class Meta:
        ordering = "-timestamp"
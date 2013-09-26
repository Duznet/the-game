from stdnet import odm
class Game(odm.StdModel):
    """Game model"""

    name = odm.SymbolField(unique = True)
    map = odm.SymbolField()
    max_players = odm.IntegerField()
    status = odm.SymbolField()

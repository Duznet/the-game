from stdnet import odm
class Game(odm.StdModel):
    """Game model"""

    name = odm.SymbolField(unique = True)
    map = odm.SymbolField()
    max_players = odm.SymbolField()
    user = odm.ForeignKey("User")
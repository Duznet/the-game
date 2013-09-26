from stdnet import odm
class Map(odm.StdModel):
    """Model for map"""

    name = odm.SymbolField(unique = True)
    map = odm.CharField()

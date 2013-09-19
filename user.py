from stdnet import odm

class User(odm.StdModel):
    """User model"""

    login = odm.SymbolField(unique = True)
    password = odm.SymbolField()
    sid = odm.SymbolField()

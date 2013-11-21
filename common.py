import re
import json

def jsonify(*args, **named):
    return named

def lower(matchobj):
    return "_" + matchobj.group(0).lower()

def camel_to_underscores(string):
    return re.sub(r'([A-Z])', lower, string)


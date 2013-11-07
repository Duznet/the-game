import re
import json

def jsonify(*args, **named):
    if len(args) == 1:
        return json.dumps(args[0])
    else:
        return json.dumps(named)

def lower(matchobj):
    return "_" + matchobj.group(0).lower()

def camel_to_underscores(string):
    return re.sub(r'([A-Z])', lower, string)


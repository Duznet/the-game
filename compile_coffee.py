import os
from glob import glob
import coffeescript

class CoffeeCompiler:
    OUTPUT_DIR = 'static/src'

    def __init__(self, dir):
        self.dir = dir 


    def compile(self):
        for filename in glob(os.path.join(self.dir, "*.coffee")):
            file = open(filename, "r")
            basename = os.path.basename(filename)
            output = open(os.path.join(self.OUTPUT_DIR, basename), "w")
            output.write(coffeescript.compile(file.read()))





import os
from glob import glob
import coffeescript

class CoffeeCompiler:
    OUTPUT_DIR = 'static/src'

    def __init__(self, dir):
        self.dir = dir


    def compile(self):
        if not os.path.exists(self.OUTPUT_DIR):
            os.mkdir(self.OUTPUT_DIR)

        for filename in glob(os.path.join(self.dir, "*.coffee")):
            file = open(filename, "r")
            basename = os.path.basename(filename)
            output = open(os.path.join(self.OUTPUT_DIR, os.path.splitext(basename)[0] + ".js"), "w")
            output.write(coffeescript.compile(file.read()))





import os
from glob import glob
import fnmatch
import coffeescript

class CoffeeCompiler:
    OUTPUT_DIR = 'static/src'

    def __init__(self, dir):
        self.dir = dir


    def compile(self):
        if not os.path.exists(self.OUTPUT_DIR):
            os.mkdir(self.OUTPUT_DIR)
        for root, dirnames, filenames in os.walk(self.dir):
            for dirname in dirnames:
                for filename in glob(os.path.join(self.dir, dirname, "*.coffee")):
                    file = open(filename, "r")
                    basename = os.path.basename(filename)

                    folder = os.path.join(self.OUTPUT_DIR, dirname)
                    if not os.path.exists(folder):
                        os.mkdir(folder)

                    output = open(os.path.join(folder, os.path.splitext(basename)[0] + ".js"), "w")
                    output.write(coffeescript.compile(file.read()))





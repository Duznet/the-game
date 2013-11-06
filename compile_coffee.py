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

        for root, dirnames, filenames in os.walk("./"):
            for dirname in dirnames:
                for filename in glob(os.path.join(root, dirname, "*.coffee")):
                    file = open(filename, "r")
                    basename = os.path.basename(filename)

                    filename = filename.replace(self.dir, self.OUTPUT_DIR)
                    dirname = os.path.dirname(filename)

                    if not os.path.exists(dirname):
                        os.mkdir(dirname)

                    print(filename)

                    output = open(os.path.join(os.path.splitext(filename)[0] + ".js"), "w")
                    output.write(coffeescript.compile(file.read()))





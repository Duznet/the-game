from math import *
from engine.constants import *

class Segment:
    def __init__(self, p1, p2):
        self.p1 = p1
        self.p2 = p2

    def __repr__(self):
        return str([self.p1, self.p2])


    def intersects_with_player(self, player):
        ipoint = [0, 0]

        for i in range(2):
            coord = list(sorted([self.p1.args[i], self.p2.args[i]]))
            pcoord = list(sorted([player.args[i] - SIDE, player.args[i] + SIDE]))

            if pcoord[1] < coord[0] or pcoord[0] > coord[1]:
                return None

            ipoint[i] = pcoord[0] if coord[0] <= pcoord[0] and pcoord[0] <= coord[1] else pcoord[1]


        return Point(ipoint)


class Point:
    def __init__(self, x, y=None):
        if y is None:
            self.x = x[0]
            self.y = x[1]
        else:
            self.x = x
            self.y = y

    def norm(self):
        return Point(-self.y, self.x)

    def dot(self, other):
        return self.x * other.x + self.y * other.y

    @property
    def args(self):
        return [self.x, self.y]

    def __repr__(self):
        return "Point" + str(self.args)

    def __add__(self, other):
        return Point(self.x + other.x, self.y + other.y)

    def __mul__(self, num):
        return Point(self.x * num, self.y * num)

    def __neg__(self):
        return self * (-1)

    def __sub__(self, other):
        return self + (-other)

    def __abs__(self):
        return sqrt(self.dot(self))

    def __div__(self, num):
        return Point(self.x / num, self.y / num)

    def __hash__(self):
        return hash((self.x, self.y))

    def __eq__(self, other):
        return self.x == other.x and self.y == other.y

    def __truediv__(self, num):
        self.x /= num
        self.y /= num
        return self

    def distance(self, other):
        return abs(self - other)

    def midpoint(self, other):
        return (self + other) / 2


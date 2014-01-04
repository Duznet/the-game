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

    def cells_path(self, lbound, ubound):
        """Bresenham's line algorithm"""
        res = []

        (x0, y0) = self.p1.args
        (x1, y1) = self.p2.args

        dx = abs(x1 - x0)
        dy = abs(y1 - y0)
        x, y = x0, y0
        sx = -1 if x0 > x1 else 1
        sy = -1 if y0 > y1 else 1
        if dx > dy:
            err = dx / 2.0
            while x != x1:
                pt = Point(x, y)
                if pt >= lbound and pt <= ubound:
                    res.append(pt)
                else:
                    return res
                err -= dy
                if err < 0:
                    y += sy
                    err += dx
                x += sx
        else:
            err = dy / 2.0
            while y != y1:
                pt = Point(x, y)
                if pt >= lbound and pt <= ubound:
                    res.append(pt)
                else:
                    return res
                err -= dx
                if err < 0:
                    x += sx
                    err += dy
                y += sy

        pt = Point(x, y)
        if pt >= lbound and pt <= ubound:
            res.append(pt)
        else:
            return res

        return res


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

    def __ge__(self, other):
        return self.x >= other.x and self.y >= other.y

    def __le__(self, other):
        return self.x <= other.x and self.y <= other.y

    def __truediv__(self, num):
        self.x /= num
        self.y /= num
        return self

    def distance(self, other):
        return abs(self - other)

    def midpoint(self, other):
        return (self + other) / 2

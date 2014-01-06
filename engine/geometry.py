from math import *
from engine.constants import *

# import sympy.geometry as geom

def pfloor(point):
    return [floor(point.x), floor(point.y)]

def pceil(point):
    return [ceil(point.x), ceil(point.y)]


class Segment:
    def __init__(self, p1, p2):
        self.p1 = p1
        self.p2 = p2

    def __repr__(self):
        return str([self.p1, self.p2])

    def vector(self):
        return self.p2 - self.p1

    def intersect_with_segment(self, seg):
        v1 = (seg.p2.x - seg.p1.x) * (self.p1.y - seg.p1.y) - (seg.p2.y - seg.p1.y) * (self.p1.x - seg.p1.x)
        v2 = (seg.p2.x - seg.p1.x) * (self.p2.y - seg.p1.y) - (seg.p2.y - seg.p1.y) * (self.p2.x - seg.p1.x)
        v3 = (self.p2.x - self.p1.x) * (seg.p1.y - self.p1.y) - (self.p2.y - self.p1.y) * (seg.p1.x - self.p1.x)
        v4 = (self.p2.x - self.p1.x) * (seg.p2.y - self.p1.y) - (self.p2.y - self.p1.y) * (seg.p2.x - self.p1.x)
        return (v1 * v2 <= 0) and (v3 * v4 <= 0)

    def intersects_with_player_accurate(self, player):
        lbound = player - Point(SIDE, SIDE)
        ubound = player + Point(SIDE, SIDE)

        pts = [lbound, lbound + Point(0, SIDE), ubound, lbound + Point(SIDE, 0), lbound]

        for i in range(len(pts) - 1):
            # this = geom.Segment(self.p1.args, self.p2.args)
            # if this.intersection(geom.Segment(pts[i].args, pts[i + 1].args)):
            if self.intersect_with_segment(Segment(pts[i], pts[i + 1])):
                return player

        return None



    def intersects_with_player(self, player):
        lbound = player - Point(SIDE, SIDE)
        ubound = player + Point(SIDE, SIDE)




        pts = [self.p1, self.p2]

        for p in pts:
            if lbound <= p <= ubound:
                return player

        return None

    def closest_wall(self, map_):
        lbound = Point(0, 0)
        ubound = Point(len(map_[0]) - 1, len(map_) - 1)
        res = []

        (x0, y0) = self.p1.args
        (x1, y1) = self.p2.args

        dx = abs(x1 - x0)
        dy = abs(y1 - y0)

        sx = -1 if x0 > x1 else 1
        sy = -1 if y0 > y1 else 1

        # print("path: ", Point(x0, y0), Point(x1, y1))

        x, y = x0, y0

        while (x1 - x)*sx > 0 and dx != 0:
            dx_ = x - floor(x) if sx == 1 else x - ceil(x)

            dy_ = sx * sy * dx_ * dy / dx
            # if sx == 1:
            #     dy_ = -dy_

            pt = Point(x - dx_, y - dy_)
            if (pt.y - y0) * sy < 0 or (pt.x - x0) * sx < 0:
                y += sy *  dy / dx
                x += sx
                continue
            cell = Point(pfloor(pt))
            if sx == -1:
                cell.x -= 1

            # print(cell)
            # print(pt)
            if cell >= lbound and cell <= ubound:
                # res[0].append(pt)
                if map_[cell.y][cell.x] == WALL:
                    res.append(pt)
                    break
            else:
                break

            y += sy *  dy / dx
            x += sx

        # print("-------------------")
        x, y = x0, y0
        while (y1 - y)*sy > 0 and dy != 0:
            dy_ = y - floor(y) if sy == 1 else y - ceil(y)
            dx_ = sy * sx * dy_ * dx / dy
            # if sy == 1:
            #     dx_ = -dx_

            pt = Point(x - dx_, y - dy_)
            if (pt.y - y0) * sy < 0 or (pt.x - x0) * sx < 0:
                x += sx *  dx / dy
                y += sy
                continue
            # cell = Point(pceil(pt)) - Point(0, 1) if sy == -1 else Point(pfloor(pt))
            cell = Point(pfloor(pt))
            if sy == -1:
                cell.y -= 1
            #     cell = Point(pceil(pt)) - Point(1,1)
            # print(cell)
            # print(pt)
            if cell >= lbound and cell <= ubound:
                # res[0].append(pt)
                if map_[cell.y][cell.x] == WALL:
                    res.append(pt)
                    break
            else:
                break

            x += sx *  dx / dy
            y += sy

        if len(res):
            return min(res, key=lambda x: self.p1.distance(x))
        else:
            pt = Point(pfloor(self.p2))
            if map_[pt.y][pt.x] == WALL:
                return self.p2
            else:
                return None

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

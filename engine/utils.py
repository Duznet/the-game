from engine.geometry import *
from engine.event import *
from engine.constants import *
from math import *

import re
def cell_coords(point):
    return Point(floor(point.x), floor(point.y))

def is_inside_rect(point, lbound, ubound):
    return point >= lbound and point <= ubound

def dist(first, second):
    return abs(second - first)

def sign(x):
    return 0 if x == 0 else x / abs(x)

def angle(dx, dy):
        res = atan2(dy, dx)
        if res < 0:
            res += 2 * pi

        res *= 180 / pi

        return res

def normalize_map(map, wall):
    if not map or not map[0]:
        return map

    result = []
    wallstr = wall * (len(map[0]) + 2)
    result.append(wallstr)
    for row in map:
        result.append(wall + row + wall)

    result.append(wallstr)
    return result


def collision_time(player, segment, v):
    minp = player - Point(SIDE, SIDE) #+ Point(EPS, EPS)
    maxp = player + Point(SIDE, SIDE) #- Point(EPS, EPS)

    minsegp = lambda i: min(segment.p1.args[i], segment.p2.args[i])
    maxsegp = lambda i: max(segment.p1.args[i], segment.p2.args[i])

    d = [0, 0]
    is_one_point_collision = [False, False]

    t = [0, 0]
    for i in range(2):
        d1 = minp.args[i] - maxsegp(i)
        d2 = minsegp(i) - maxp.args[i]


        if (segment.p1.args[i] == segment.p2.args[i]) and d1 < -EPS and d2 < -EPS:
            return None

        is_one_point_collision[i] = d1 == 0 or d2 == 0
        if d1 > 0:
            d[i] = -d1
        elif d2 > 0:
            d[i] = d2
        else:
            d[i] = 0


    # for i in range(2):
        if d[i] == 0:
            continue

        if (v.args[i] == 0):
            return None

        t[i] = d[i] / v.args[i]

        if (t[i] < 0 or t[i] > 1):
            return None

        if d1 < 0 and d2 < 0:
            t[i] = -1


    for i in range(2):
        if segment.p1.args[i] == segment.p2.args[i]:
            if (t[i] < t[(i + 1) % 2] or d[(i + 1) % 2] == 0 and
                v.args[(i + 1) % 2] == 0 and is_one_point_collision[(i + 1) % 2]):
                return None
            else:
                return Collision(t[i], Point(d), segment)
        elif t[0] == t[1] == 0 and (abs(minp.args[i] - minsegp(i)) == 1 and abs(maxp.args[i] - maxsegp(i)) == 1):
            return None


    return Collision(t[0], Point(d), segment)


def is_vertical(segment):
    return segment.p1.x == segment.p2.x

def is_teleport(sym):
    return re.match(PORTAL, sym)

def is_weapon(sym):
    return re.match(WEAPON, sym)

def is_health(sym):
    return sym == HEALTH

def underpoint(player):
    return Point(floor(player.x), floor(player.y + SIDE))

def is_inner_side(map_, segment):
    mid = segment.p1.midpoint(segment.p2)

    fd = Point(-0.5, 0) if is_vertical(segment) else Point(0, -0.5)
    sd = Point(0.5, 0) if is_vertical(segment) else Point(0, 0.5)

    first = cell_coords(mid + fd)
    second = cell_coords(mid + sd)
    # print(first, second)
    try:
        return map_[first.y][first.x] == WALL and map_[second.y][second.x] == WALL
    except IndexError:
        return True

def get_sides(cell):
    points = [cell, cell + Point(1, 0), cell + Point(1, 1), cell + Point(0, 1)]
    sides = []
    for i in range(len(points)):
        sides.append(Segment(points[i], points[(i + 1) % len(points)]))

    return sides

def get_visible_sides(cell, v):
    sides = get_sides(cell)

    return list(filter(lambda side: (side.p2 - side.p1).norm().dot(v) > 0, sides))

def get_wall_collisions(map_, player, v):
    cur_cell = cell_coords(player)
    print("player: ", cur_cell)
    walls = []

    for i in [-1, 0, 1]:
        for j in [-1, 0, 1]:
            cell = cur_cell + Point(i, j)
            print("cell: ", cell)
            if (i != 0 or j != 0) and map_[cell.y][cell.x] == WALL:
                walls.append(cell)

    sides = []
    for wall in walls:
        sides += get_visible_sides(wall, v)

    sides = [side for side in sides if not is_inner_side(map_, side)]
    print("sides count: ", len(sides))

    collisions = [col for col in map(lambda side: collision_time(player, side, v), sides) if col]

    if collisions:
        first = min(collisions, key=lambda x: x.time)
        print("first: ", first.time, first.offset, first.segment)

        collisions = [col for col in collisions if col.time == first.time]

    if collisions:
        return [WallCollisionEvent(collisions)]
    else:
        return []


def collision_with_point(player, v, point):
    minp = player - Point(SIDE, SIDE)
    maxp = player + Point(SIDE, SIDE)

    # for i in range(2):
    #     if v.args[i] < 0:
    #         minp.args[i] += v.args[i]
    #     else:
    #         maxp.args[i] += v.args[i]

    d = [0, 0]
    t = [0, 0]
    is_one_point_collision = [False, False]

    for i in range(2):
        d1 = minp.args[i] - point.args[i]

        d2 = point.args[i] - maxp.args[i]
        if d1 >= 0:
            d[i] = -d1 - EPS
        elif d2 >= 0:
            d[i] = d2 + EPS
        else:
            d[i] = 0
            continue

        # if (abs(v.args[i]) < EPS):
        #     return None

        minarg = minp.args[i]
        maxarg = maxp.args[i]
        minarg = min(minarg, minarg + v.args[i])
        maxarg = max(maxarg, maxarg + v.args[i])

        if not (minarg < point.args[i] < maxarg):
            return None

        t[i] = d[i] / v.args[i]

        print("t:", t[i])
        print(d, v)
        print("d", d[i])

        if (t[i] < 0 or t[i] > 1):
            return None
    return Collision(max(t), Point(d), Segment(point, point))


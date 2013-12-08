
# from sympy.geometry import Point
from sympy.geometry.util import *
import re

import copy
from math import *

EPS = 1e-6

class Segment:
    def __init__(self, p1, p2):
        self.p1 = p1
        self.p2 = p2

    def __repr__(self):
        return str([self.p1, self.p2])


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

    def __truediv__(self, num):
        self.x /= num
        self.y /= num
        return self

    def distance(self, other):
        return abs(self - other)

    def midpoint(self, other):
        return (self + other) / 2



class Player:
    DEFAULT_HP = 100
    MAX_VELOCITY = 0.3

    def __init__(self, point):
        self.point = point
        self.velocity = Point(0, 0)
        self.hp = self.DEFAULT_HP
        self.score = 0
        self.moved = False
        self.got_action = False

    def normalize_v(self):
        x = self.velocity.x
        if abs(x) > self.MAX_VELOCITY:
            x /= abs(x)
            x *= self.MAX_VELOCITY

        y = self.velocity.y
        if abs(y) > self.MAX_VELOCITY:
            y /= abs(y)
            y *= self.MAX_VELOCITY

        self.velocity = Point(x, y)
        return self

def cell_coords(point):
    return Point(floor(point.x), floor(point.y))

def sign(x):
    return 0 if x == 0 else x / abs(x)

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

class Collision:
    def __init__(self, time, offset, segment):
        self.time = time
        self.offset = offset
        self.segment = segment

    def __repr__(self):
        return "Collision" + str([self.time, self.offset, self.segment])

class Game:
    DEFAULT_VELOCITY = 0.02
    SIDE = 0.5
    PLAYER_POS = Point(0.5, 0.5)
    GRAVITY = 0.02

    WALL = '#'
    SPAWN = '$'
    SPACE = '.'
    PORTAL = '[0-9]'

    NEXT_PORTAL = {}
    NEXT_SPAWN = {}

    def __init__(self, map):
        self.first_spawn = Point(1, 1)
        self.players_ = {}
        self.players_order = []
        self.tick = 0
        self.first_portal = {}

        self.map = normalize_map(map, self.WALL)

        print(self.map)

        last_spawn = None
        last_portal = {}
        for y, row in enumerate(self.map):
            for x, cell in enumerate(row):
                if cell == self.SPAWN:
                    if last_spawn:
                        self.NEXT_SPAWN[last_spawn] = Point(x, y)
                    else:
                        self.first_spawn = Point(x, y)

                    last_spawn = Point(x, y)

                if re.match(self.PORTAL, cell):
                    if last_portal.get(cell):
                        self.NEXT_PORTAL[last_portal[cell]] = Point(x, y)
                    else:
                        self.first_portal[cell] = Point(x, y)

                    last_portal[cell] = Point(x, y)

        self.NEXT_SPAWN[last_spawn] = self.first_spawn

        for key in last_portal.keys():
            lp = last_portal.get(key)

            if lp:
                self.NEXT_PORTAL[lp] = self.first_portal[key]

    def next_tick(self, is_sync):
        for player in self.players_.values():
            if not player.got_action and is_sync:
                return False

        self.tick += 1
        self.moveall()

        return True

    def update_players(self):
        for player in self.players_.values():
            player.got_action = False

    @staticmethod
    def is_on_my_way(path_bound, cell):
        cell = Polygon(cell, Point(cell.x, cell.y + 1), cell + Point(1, 1), Point(cell.x + 1, cell.y))

        return path_bound.intersection(cell)

    @staticmethod
    def path_bound(start, end):
        pts = []
        for signx in [-1, 1]:
            for signy in [-1, 1]:
                pts.append(Point(start.x + signx * Game.SIDE, start.y + signy * Game.SIDE))
                pts.append(Point(end.x + signx * Game.SIDE, end.y + signy * Game.SIDE))

        return convex_hull(*pts)

    @staticmethod
    def player_bound(point):
        pts = []
        for signx in [-1, 1]:
            for signy in [-1 * signx, 1 * signx]:
                pts.append(Point(start.x + signx * Game.SIDE, start.y + signy * Game.SIDE))

    @staticmethod
    def collision_time(player, segment, v):
        minp = player - Point(Game.SIDE, Game.SIDE)
        maxp = player + Point(Game.SIDE, Game.SIDE)

        d = [0, 0]
        is_one_point_collision = [False, False]

        for i in range(2):
            d1 = minp.args[i] - max(segment.p1.args[i], segment.p2.args[i])
            d2 = min(segment.p1.args[i], segment.p2.args[i]) - maxp.args[i]

            if d1 > 0:
                d[i] = -d1
            elif d2 > 0:
                d[i] = d2
            else:
                d[i] = 0

            is_one_point_collision[i] = d1 == 0 or d2 == 0

        print("delta: ", d)

        t = [0, 0]
        for i in range(2):
            if d[i] == 0:
                continue

            if (v.args[i] == 0):
                return None

            t[i] = d[i] / v.args[i]

            if (t[i] < 0 or t[i] > 1):
                return None

        for i in range(2):
            if segment.p1.args[i] == segment.p2.args[i]:
                if (t[i] < t[(i + 1) % 2] or d[(i + 1) % 2] == 0 and
                    v.args[(i + 1) % 2] == 0 and is_one_point_collision[(i + 1) % 2]):
                    return None
                else:
                    return Collision(t[i], Point(d), segment)

        return Collision(t[0], Point(d), segment)

    @staticmethod
    def is_vertical(segment):
        return segment.p1.x == segment.p2.x

    @staticmethod
    def is_inner_side(map_, segment):
        mid = segment.p1.midpoint(segment.p2)

        fd = Point(-0.5, 0) if Game.is_vertical(segment) else Point(0, -0.5)
        sd = Point(0.5, 0) if Game.is_vertical(segment) else Point(0, 0.5)

        first = cell_coords(mid + fd)
        second = cell_coords(mid + sd)

        return map_[first.y][first.x] == Game.WALL and map_[second.y][second.x] == Game.WALL

    @staticmethod
    def get_sides(cell):
        points = [cell, cell + Point(1, 0), cell + Point(1, 1), cell + Point(0, 1)]
        sides = []
        for i in range(len(points)):
            sides.append(Segment(points[i], points[(i + 1) % len(points)]))

        return sides

    @staticmethod
    def get_visible_sides(cell, v):
        sides = Game.get_sides(cell)

        return list(filter(lambda side: (side.p2 - side.p1).norm().dot(v) > 0, sides))

    @staticmethod
    def get_wall_collisions(map_, player, v):
        cur_cell = cell_coords(player)
        print("player: ", cur_cell)
        walls = []

        for i in [-1, 0, 1]:
            for j in [-1, 0, 1]:
                cell = cur_cell + Point(i, j)
                if (i != 0 or j != 0) and map_[cell.y][cell.x] == Game.WALL:
                    walls.append(cell)

        sides = []
        for wall in walls:
            sides += Game.get_visible_sides(wall, v)

        sides = [side for side in sides if not Game.is_inner_side(map_, side)]
        print("sides count: ", len(sides))

        collisions = [col for col in map(lambda side: Game.collision_time(player, side, v), sides) if col]

        if collisions:
            first = min(collisions, key=lambda x: x.time)
            print("first: ", first.time, first.offset, first.segment)

            collisions = [col for col in collisions if col.time == first.time]

        return collisions

    def can_teleport(self, player):
        tp = cell_coords(player)

        if not re.match(self.PORTAL, self.map[tp.y][tp.x]):
            return False

        tp = Point(tp.x + self.SIDE, tp.y + self.SIDE)

        return (tp.x <= player.x + Game.SIDE and tp.x >=     player.x - Game.SIDE and
            tp.y <= player.y + Game.SIDE and tp.y >= player.y - Game.SIDE)


    def cells_path(self, start, end):
        path = []
        bound = self.path_bound(start, end)
        for x in range(floor(start.x), floor(end.x) + 1):
            for y in range(floor(start.y), floor(end.y) + 1):
                if self.is_on_my_way(bound, Point(x, y)):
                    path.append(Point(x, y))

        return path

    def players(self):
        result = [{
            'x': float(self.players_[id].point.x - 1),
            'y': float(self.players_[id].point.y - 1),
            'vx': float(self.players_[id].velocity.x),
            'vy': float(self.players_[id].velocity.y),
            'hp': self.players_[id].hp
            } for id in self.players_order]
        print(result)
        return result

    def player_ids(self):
        return self.players_order

    def players_count(self):
        return len(self.players_order)

    def add_player(self, id):
        self.players_[id] = Player(self.first_spawn + self.PLAYER_POS)
        self.players_order.append(id)
        print("add player: ", self.players_[id].got_action)
        return self.players_[id]

    def remove_player(self, id):
        self.players_.pop(id)
        self.players_order.remove(id)

    @staticmethod
    def underpoint(player):
        return Point(floor(player.x), floor(player.y + Game.SIDE))

    def update_v(self, id, dx, dy):
        player = self.players_[id]


        if (dx != 0):
            delta = Point(dx, 0)
            delta /= abs(delta)

            player.velocity += delta * self.DEFAULT_VELOCITY

            player.normalize_v()

        player.moved = True

        uleft = self.underpoint(player.point - Point(self.SIDE - EPS, 0))
        uright = self.underpoint(player.point + Point(self.SIDE - EPS, 0))


        if self.map[uleft.y][uleft.x] != self.WALL and self.map[uright.y][uright.x] != self.WALL:
            return player

        player.velocity.y = -Player.MAX_VELOCITY if dy < 0 else 0

        return player

    def fall_down_if_need(self, id):
        player = self.players_[id]

        y = player.velocity.y

        uleft = self.underpoint(player.point - Point(self.SIDE - EPS, 0))
        uright = self.underpoint(player.point + Point(self.SIDE - EPS, 0))

        if self.map[uleft.y][uleft.x] != self.WALL and self.map[uright.y][uright.x] != self.WALL:
            print("gravity")
            y += self.GRAVITY

        player.velocity = Point(player.velocity.x, y)

        return player

    def brake_if_not_moved(self, id):
        player = self.players_[id]

        if player.moved:
            return player

        norm = player.velocity.distance(Point(0, 0))

        uleft = self.underpoint(player.point - Point(self.SIDE - EPS, 0))
        uright = self.underpoint(player.point + Point(self.SIDE - EPS, 0))

        if norm == 0 or self.map[uleft.y][uleft.x] != self.WALL and self.map[uright.y][uright.x] != self.WALL:
            return player

        brake_v = player.velocity * self.DEFAULT_VELOCITY / norm

        x = player.velocity.x
        y = player.velocity.y
        x = 0 if brake_v.x > x else x - brake_v.x
        y = 0 if brake_v.y > y else y - brake_v.y
        player.velocity = Point(x, y)

        return player

    def moveall(self):
        for id in self.players_order:
            self.move(id)

        return self

    def move(self, id):
        player = self.brake_if_not_moved(id)
        player = self.fall_down_if_need(id)

        if player.velocity == Point(0, 0):
            return self

        direction = Point(sign(player.velocity.x), sign(player.velocity.y))

        collisions = self.get_wall_collisions(self.map, player.point, player.velocity)

        print("collisions count: ", len(collisions))
        if collisions:
            print(collisions)
            player.point += collisions[0].offset
            for collision in collisions:
                if self.is_vertical(collision.segment):
                    print("vertical")
                    player.velocity = Point(0, player.velocity.y)
                else:
                    player.velocity = Point(player.velocity.x, 0)

        player.point = player.velocity + player.point

        player.moved = False

        return self
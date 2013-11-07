from sympy.geometry import Point, Segment, Polygon
from sympy.geometry.util import *

import copy
from math import *

class Player:
    DEFAULT_HP = 100
    MAX_VELOCITY = 1

    def __init__(self, point):
        self.point = point
        self.velocity = Point(0, 0)
        self.hp = self.DEFAULT_HP
        self.score = 0
        self.moved = false

    def normalize_v(self):
        if abs(self.velocity.x) > MAX_VELOCITY:
            self.velocity.x /= abs(self.velocity.x)
            self.velocity.x *= MAX_VELOCITY


        if abs(self.velocity.y) > MAX_VELOCITY:
            self.velocity.y /= abs(self.velocity.y)
            self.velocity.y *= MAX_VELOCITY

        return self

def pfloor(point):
    return Point(floor(point.x), floor(point.y))

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



class Game:
    DEFAULT_VELOCITY = 0.1
    SIDE = 0.5
    PLAYER_POS = Point(0.5, 0.5)

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
        last_spawn = None
        last_portal = {}
        for y, row in enumerate(self.map):
            for x, cell in enumerate(row):
                if cell == self.SPAWN:
                    if last_spawn:
                        NEXT_SPAWN[last_spawn] = Point(x, y)
                    else:
                        self.spawn = Point(x, y)

                    last_spawn = Point(x, y)

                if re.match('[0-9]', cell):
                    if last_portal.get(cell):
                        NEXT_PORTAL[last_portal[cell]] = Point(x, y)
                    else:
                        self.first_portal[cell] = Point(x, y)

                    last_portal[cell] = Point(x, y)

        NEXT_SPAWN[last_spawn] = self.first_spawn

        for key in last_portal.keys():
            lp = last_portal.get(key)

            if lp:
                NEXT_PORTAL[lp] = self.first_portal[key]

    def next_tick(self):
        self.tick += 1
        self.moveall()


    @staticmethod
    def is_on_my_way(path_bound, cell):
        cell = Polygon(cell, Point(cell.x, cell.y + 1), cell + Point(1, 1), Point(cell.x + 1, cell.y))

        return path_bound.intersection(cell)

    @staticmethod
    def path_bound(start, end):
        pts = []
        for signx in [-1, 1]:
            for signy in [-1, 1]:
                pts.append(Point(start.x + signx * self.SIDE, start.y + signy * self.SIDE))
                pts.append(Point(end.x + signx * self.SIDE, end.y + signy * self.SIDE))

        return convex_hull(*pts)


    def cells_path(self, start, end):
        path = []
        bound = self.path_bound(start, end)
        for x in range(floor(start.x), floor(end.x) + 1):
            for y in range(floor(start.y), floor(end.y) + 1):
                if self.is_on_my_way(bound, Point(x, y)):
                    path.append(Point(x, y))

        return path

    def players(self):
        for player in self.players_.values():
            player.point = player.point.evalf()
            player.velocity = player.velocity.evalf()

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
        return self.players_[id]

    def remove_player(self, id):
        self.players_.pop(id)
        self.players_order.remove(id)

    def update_v(self, id, dx, dy):
        player = self.players_[id]

        delta = Point(dx, dy)
        if delta.distance(Point(0, 0)) == 0:
            return self

        delta /= delta.distance(Point(0, 0))

        player.velocity += delta * self.DEFAULT_VELOCITY
        player.normalize_v()
        player.moved = True


    def brake_if_not_moved(self, id):
        player = self.players_[id]

        if player.moved:
            return player

        norm = player.velocity.distance(Point(0, 0))

        if norm == 0:
            return player

        brake_v = self.DEFAULT_VELOCITY * player.velocity / norm

        player.velocity.x = 0 if brake_v.x > player.velocity.x else player.velocity.x - brake_v.x
        player.velocity.y = 0 if brake_v.y > player.velocity.y else player.velocity.y - brake_v.y

        return player

    def moveall(self):
        for id in self.players_order:
            self.move(id)

        return self

    def move(self, id):
        player = self.brake_if_not_moved(id)

        end = player.velocity + player.point
        print(end.evalf())
        path = self.cells_path(player.point, end)

        for id, cell in enumerate(path):
            if self.map[cell.y][cell.x] == self.WALL:
                player.point = path[id - 1] + self.PLAYER_POS
                player.velocity = Point(0, 0)
                return self

        player.point = end

        player.moved = False

        return self
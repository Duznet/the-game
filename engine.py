
from sympy.geometry import *
from sympy.geometry.util import *
import re

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
        self.moved = False

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
    GRAVITY = 0.2

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

                if re.match('[0-9]', cell):
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
                pts.append(Point(start.x + signx * Game.SIDE, start.y + signy * Game.SIDE))
                pts.append(Point(end.x + signx * Game.SIDE, end.y + signy * Game.SIDE))

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
        print(self.first_spawn)
        print("before add")

        self.players_[id] = Player(self.first_spawn + self.PLAYER_POS)
        print("after")
        self.players_order.append(id)
        return self.players_[id]

    def remove_player(self, id):
        self.players_.pop(id)
        self.players_order.remove(id)

    @staticmethod
    def underpoint(player):
        return Point(floor(player.point.x), floor(player.point.y + Game.SIDE))

    def update_v(self, id, dx, dy):
        player = self.players_[id]

        delta = Point(dx, dy)

        print(delta)

        underpoint_ = self.underpoint(player)

        y = player.velocity.y
        if delta.y < 0 and self.map[underpoint_.y][underpoint_.x] == self.WALL:
            y = -Player.MAX_VELOCITY
        else:
            if self.map[underpoint_.y][underpoint_.x] != self.WALL:
                y += self.GRAVITY
            delta = Point(delta.x, 0)

        player.velocity = Point(player.velocity.x, y)
        print(player.velocity)

        if delta.distance(Point(0, 0)) == 0:
            return self

        delta /= delta.distance(Point(0, 0))

        player.velocity += delta * self.DEFAULT_VELOCITY
        print(player.velocity)

        player.normalize_v()
        player.moved = True

        return self


    def brake_if_not_moved(self, id):
        player = self.players_[id]

        if player.moved:
            return player

        norm = player.velocity.distance(Point(0, 0))

        underpoint = self.underpoint(player)

        if norm == 0 or self.map[underpoint.y][underpoint.x] != self.WALL:
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

        if player.velocity == Point(0, 0):
            return self

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
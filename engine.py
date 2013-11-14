
from sympy.geometry import *
from sympy.geometry.util import *
import re

import copy
from math import *

class Player:
    DEFAULT_HP = 100
    MAX_VELOCITY = 0.2

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

    def next_tick(self, is_sync):
        for player in self.players_.values():
            if not player.got_action and is_sync:
                return False

        self.tick += 1
        self.moveall()

        return True

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

    def can_teleport(self, player):
        tp = cell_coords(player.point)

        if self.map[tp.y][tp.x] != self.PORTAL:
            return False

        tp = Point(tp.x + self.SIDE, tp.y + self.SIDE)

        return (tp.x < player.x + Game.SIDE and tp.x > player.x - Game.SIDE and
            tp.y < player.y + Game.SIDE and tp.y > player.y - Game.SIDE)


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

    @staticmethod
    def underpoint(player):
        return Point(floor(player.point.x), floor(player.point.y + Game.SIDE))

    def update_v(self, id, dx, dy):
        player = self.players_[id]

        delta = Point(dx, dy)

        print(delta)

        underpoint_ = self.underpoint(player)

        y = player.velocity.y
        print("underpoint is: ", underpoint_, " ", self.map[underpoint_.y][underpoint_.x])
        if delta.y < 0 and self.map[underpoint_.y][underpoint_.x] == self.WALL:
            y = -Player.MAX_VELOCITY

        player.velocity = Point(player.velocity.x, y)
        print(player.velocity)

        if delta.distance(Point(0, 0)) == 0:
            return player

        delta /= delta.distance(Point(0, 0))

        player.velocity += delta * self.DEFAULT_VELOCITY
        print(player.velocity)

        player.normalize_v()
        player.moved = True

        return player

    def fall_down_if_need(self, id):
        player = self.players_[id]

        y = player.velocity.y
        underpoint_ = self.underpoint(player)
        if self.map[underpoint_.y][underpoint_.x] != self.WALL:
            print("gravity")
            y += self.GRAVITY

        player.velocity = Point(player.velocity.x, y)

        return player

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
        player = self.fall_down_if_need(id)

        if player.velocity == Point(0, 0):
            return self

        end = player.velocity + player.point
        direction = Point(sign(player.velocity.x), sign(player.velocity.y))

        print(end.evalf())
        end_cell = cell_coords(end + direction * self.SIDE)
        start_cell = cell_coords(player.point)
        vcell = Point(start_cell.x, end_cell.y)
        hcell = Point(end_cell.x, start_cell.y)
        vx = player.velocity.x
        vy = player.velocity.y
        endx = end.x
        endy = end.y
        print(end_cell)
        print(self.map[vcell.y][vcell.x])
        if self.map[vcell.y][vcell.x] == self.WALL:
            print("WALLV")
            endy = start_cell.y + self.SIDE
            vy = 0

        print(self.map[hcell.y][hcell.x])
        if self.map[hcell.y][hcell.x] == self.WALL:
            print("WALLH")
            endx = start_cell.x + self.SIDE
            vx = 0


        print(self.map[vcell.y][hcell.x])
        if self.map[vcell.y][hcell.x] == self.WALL and start_cell.x != end_cell.x and start_cell.y != end_cell.y:
            cell_center = end_cell + Point(self.SIDE, self.SIDE)
            centers = cell_center - player.point
            centers = Point(sign(centers.x), sign(centers.y))

            pcorner = player.point + centers * self.SIDE
            wcorner = cell_center - centers * self.SIDE

            corners = wcorner - pcorner

            if vy * corners.x <= vx * corners.y:
                vy = 0
                endy = start_cell.y + self.SIDE

            if vy * corners.x >= vx * corners.y:
                vx = 0
                endx = start_cell.x + self.SIDE

        player.point = Point(endx, endy)
        player.velocity = Point(vx, vy)

        if self.can_teleport(player):
            cell = cell_coords(player.point)
            player.point = self.NEXT_PORTAL[cell] + Point(self.SIDE, self.SIDE)

        player.moved = False

        return self
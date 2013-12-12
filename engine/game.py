from engine.geometry import Point
from engine.utils import *
from engine.constants import *
from engine.event import *

import re
import sys

import copy

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
        self.delta = Point(0, 0)

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

class Game:
    DEFAULT_VELOCITY = 0.02
    PLAYER_POS = Point(0.5, 0.5)
    GRAVITY = 0.02

    NEXT_PORTAL = {}
    NEXT_SPAWN = {}

    def __init__(self, map):
        self.first_spawn = Point(1, 1)
        self.players_ = {}
        self.players_order = []
        self.tick = 0
        self.first_portal = {}

        self.map = normalize_map(map, WALL)

        print(self.map)

        last_spawn = None
        last_portal = {}
        for y, row in enumerate(self.map):
            for x, cell in enumerate(row):
                if cell == SPAWN:
                    if last_spawn:
                        self.NEXT_SPAWN[last_spawn] = Point(x, y)
                    else:
                        self.first_spawn = Point(x, y)

                    last_spawn = Point(x, y)

                if re.match(PORTAL, cell):
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


    def get_teleport_collisions(self, player, v):
        curcell = cell_coords(player)

        dir = Point(sign(v.x), sign(v.y))

        cells = [curcell + Point(x, y) for x in [0, dir.x] for y in [0, dir.y] if x != 0 or y != 0]

        collisions = []
        for cell in cells:
            cell = cell_coords(cell)
            if is_teleport(self.map[cell.y][cell.x]):
                collisions.append(collision_with_point(player, v, cell + Point(0.5, 0.5)))

        collisions = list(filter(None, collisions))

        if collisions:
            first = min(collisions, key=lambda col: col.time)

            return TeleportEvent(first.time, self.NEXT_PORTAL[cell_coords(first.segment.p1)] + Point(0.5, 0.5))
        else:
            return None


    def get_events(self, player, v):
        events = []
        events.append(get_wall_collisions(self.map, player, v))
        events.append(self.get_teleport_collisions(player, v))
        print(events[-1])

        return sorted(filter(None, events), key=lambda event: event.time)

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

    def update_v(self, id, dx, dy):
        player = self.players_[id]


        if (dx != 0):
            player.delta = Point(dx, 0)
            player.delta /= abs(player.delta)

        player.moved = True

        uleft = underpoint(player.point - Point(SIDE - EPS, 0))
        uright = underpoint(player.point + Point(SIDE - EPS, 0))


        if self.map[uleft.y][uleft.x] != WALL and self.map[uright.y][uright.x] != WALL:
            return player

        player.delta.y = dy

        return player

    def fall_down_if_need(self, id):
        player = self.players_[id]

        y = player.velocity.y

        uleft = underpoint(player.point - Point(SIDE - EPS, 0))
        uright = underpoint(player.point + Point(SIDE - EPS, 0))

        if self.map[uleft.y][uleft.x] != WALL and self.map[uright.y][uright.x] != WALL:
            print("gravity")
            y += self.GRAVITY

        player.velocity = Point(player.velocity.x, y)

        return player

    def brake_if_not_moved(self, id):
        player = self.players_[id]

        print("delta: ", player.delta)
        if abs(player.delta.x) > EPS:
            return player
        print("BRAKE")
        print(player.velocity)

        norm = abs(player.velocity)

        uleft = underpoint(player.point - Point(SIDE - EPS, 0))
        uright = underpoint(player.point + Point(SIDE - EPS, 0))

        if norm == 0: #or self.map[uleft.y][uleft.x] != self.WALL and self.map[uright.y][uright.x] != self.WALL:
            return player

        brake_v = player.velocity * self.DEFAULT_VELOCITY / norm
        print("v: ", player.velocity)
        print("brake v: ", brake_v)

        x = player.velocity.x
        y = player.velocity.y
        x = 0 if brake_v.x > x else x - brake_v.x
        player.velocity = Point(x, y)

        print("result v: ", player.velocity)

        return player

    def moveall(self):
        for id in self.players_order:
            self.move(id)

        return self

    def move(self, id):
        player = self.brake_if_not_moved(id)
        player.velocity += player.delta * self.DEFAULT_VELOCITY
        if player.delta.y < 0:
            player.velocity.y = -Player.MAX_VELOCITY

        player.normalize_v()

        player = self.fall_down_if_need(id)

        if player.velocity == Point(0, 0):
            return self

        t = 0
        events = self.get_events(player.point, player.velocity)
        while events and t < 1:
            for event in events:
                event.handle(player)
                if event.require_event_refresh():
                    break

            t += event.time

            if t < 1:
                events = self.get_events(player.point, player.velocity * (1 - t))

        if t < 1:
            player.point = player.velocity * (1 - t) + player.point

        player.moved = False
        player.delta = Point(0, 0)

        return self
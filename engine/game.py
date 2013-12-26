from engine.geometry import Point
from engine.utils import *
from engine.constants import *
from engine.event import *

import re
import sys

import copy

class Projectile:
    def __init__(self, owner, point, v, weapon):
        self.owner = owner
        self.point = point
        self.v = v
        self.time = 0
        self.weapon = weapon

    def to_array(self):
        return [self.point.x - 1, self.point.y - 1, self.v.x, self.v.y, self.weapon, self.time]

class Player:
    MAX_HP = 100
    MAX_VELOCITY = 0.2

    def __init__(self, name, point):
        self.name = name
        self.point = point
        self.velocity = Point(0, 0)
        self.hp = self.MAX_HP
        self.score = 0
        self.moved = False
        self.got_action = False
        self.delta = Point(0, 0)
        self.ammo = {'K': 0, 'R': 0, 'P': 0, 'M': 0, 'A': 0}
        self.weapon = 'K'
        self.angle = -1

    def normalize_hp(self):
        self.hp = min(self.hp, self.MAX_HP)
        self.hp = max(self.hp, 0)

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
        self.player_logins = []
        self.tick = 0
        self.first_portal = {}
        self.items = []
        self.item_id = {}
        self.projectiles = []

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

                elif is_teleport(cell):
                    if last_portal.get(cell):
                        self.NEXT_PORTAL[last_portal[cell]] = Point(x, y)
                    else:
                        self.first_portal[cell] = Point(x, y)

                    last_portal[cell] = Point(x, y)

                elif is_weapon(cell) or is_health(cell):
                    self.item_id[Point(x, y)] = len(self.items)
                    self.items.append(0)


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
        for item in self.items:
            item -= 1
            item = max(0, item)

        self.move_projectiles()

        self.moveall()

        return True

    def move_projectiles(self):
        for i in range(len(self.projectiles)):
            self.move_projectile(i)

        self.projectiles = list(filter(None, self.projectiles))

        for p in self.projectiles:
            p.time += 1

    def move_projectile(self, id):
        projectile = self.projectiles[id]
        bullet_path = Segment(projectile.point, projectile.point + projectile.v)

        curcell = cell_coords(projectile.point)
        dir = Point(sign(projectile.v.x), sign(projectile.v.y))
        cells = [curcell + Point(x, y) for x in [0, dir.x] for y in [0, dir.y] if x != 0 or y != 0]

        collisions = []
        for cell in cells:
            cell = cell_coords(cell)
            cellval = self.map[cell.y][cell.x]

            if cellval == WALL:
                self.projectiles[id] = None
                return


        for player in self.players_.values():
            if player == projectile.owner:
                continue
            if bullet_path.intersects_with_player(player.point):
                player.hp -= DAMAGE[projectile.weapon]
                player.normalize_hp()

                self.projectiles[id] = None

        projectile.point += projectile.v

    def update_players(self):
        for player in self.players_.values():
            player.got_action = False


    def get_item_collisions(self, player, v):
        curcell = cell_coords(player)

        dir = Point(sign(v.x), sign(v.y))

        cells = [curcell + Point(x, y) for x in [0, dir.x] for y in [0, dir.y] if x != 0 or y != 0]

        collisions = []
        for cell in cells:
            cell = cell_coords(cell)
            cellval = self.map[cell.y][cell.x]
            if cellval != WALL and cellval != SPACE:
                collision = collision_with_point(player, v, cell + Point(0.5, 0.5))

                if not collision:
                    continue

                if is_teleport(cellval):
                    collisions.append(TeleportEvent(collision.time, self.NEXT_PORTAL[cell] + Point(SIDE, SIDE)))
                elif is_weapon(cellval):
                    collisions.append(WeaponPick(collision.time, self.items, self.item_id[cell], cellval))
                elif is_health(cellval):
                    collisions.append(HealthPick(collision.time, self.items, self.item_id[cell]))


        return collisions


    def get_pick_events(self, player, v):
        pass

    def get_events(self, player, v):
        events = get_wall_collisions(self.map, player, v)
        events += self.get_item_collisions(player, v)

        return events

    def players(self):
        result = [[
                    float(self.players_[id].point.x - 1),
                    float(self.players_[id].point.y - 1),
                    float(self.players_[id].velocity.x),
                    float(self.players_[id].velocity.y),
                    self.players_[id].weapon,
                    self.players_[id].angle,
                    self.players_[id].name,
                    self.players_[id].hp,
                    self.players_[id].score,
                    self.players_[id].score
                    ] for id in self.players_order]
        print(result)
        return result

    def active_items(self):
        items = [i for i in range(len(self.items)) if self.items[i] == 0]
        print(items)
        return items

    def player_ids(self):
        return self.players_order

    def players_count(self):
        return len(self.players_order)

    def add_player(self, id, login):
        self.players_[id] = Player(login, self.first_spawn + self.PLAYER_POS)
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

    def fire(self, id, dx, dy):
        player = self.players_[id]

        dir = Point(dx, dy)
        if (abs(dir) == 0 or player.ammo[player.weapon] == 0):
            return player

        dir /= abs(dir)

        player.ammo[player.weapon] -= 1

        self.projectiles.append(Projectile(player, player.point, dir * PROJV[player.weapon], player.weapon))
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
        x = 0 if abs(brake_v.x) > abs(x) else x - brake_v.x
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
            refresh = False
            tevent = 0
            for event in events:
                tevent = max(tevent, event.time)
                if t + tevent > 1:
                    break

                print(event)
                event.handle(player)

                if event.require_event_refresh():
                    events = self.get_events(player.point, player.velocity * (1 - t - tevent - EPS))
                    refresh = True
                    break

            t += tevent
            if not refresh:
                events = []


        if t < 1:
            player.point = player.velocity * (1 - t) + player.point

        player.moved = False
        player.delta = Point(0, 0)

        return self
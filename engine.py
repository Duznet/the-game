from sympy.geometry import Point, Segment
from math import *

class Player:
    DEFAULT_HP = 100

    def __init__(self, x, y):
        self.point = Point(x, y)
        self.velocity = 0
        self.hp = self.DEFAULT_HP
        self.score = 0


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
    _players = {}
    players_order = []
    platforms = []

    DEFAULT_VELOCITY = 0.5

    WALL = '#'
    SPAWN = '$'
    SPACE = '.'

    spawn = Point(0, 0)

    def __init__(self, map):
        self.map = normalize_map(map, self.WALL)
        for y, row in enumerate(map):
            for x, cell in enumerate(row):
                if cell == self.SPAWN:
                    self.spawn = Point(x, y)

            l = 0
            r = l
            while r < len(row):
                if row[l] != self.WALL:
                    r += 1
                    l += 1
                elif row[r] == row[l]:
                    r += 1
                else:
                    platforms.append(Segment(Point(l, y), Point(r - 1, y)))


    def fall_if_need(self, point):
        cell = pfloor(point)

        if self.map[cell.y + 1][cell.x] == self.WALL:
            return point

        for y in range(cell.y, len(self.map) - 1):
            if map[y][cell.x] == self.WALL:
                return Point(y - 1, x)

    def players(self):
        return [self._players[id] for id in self.players_order]

    def player_ids(self):
        return self.players_order

    def add_player(self, id):
        self._players[id] = Player(self.spawn.x, self.spawn.y)
        self.players_order.append(id)
        return self._players[id]

    def move(self, id, dx, dy):
        delta = Point(dx, dy)
        delta /= delta.distance(Point(0, 0))
        player = _players[id]

        path = Segment(player.point, player.point + self.DEFAULT_VELOCITY * delta)

        for platform in platforms:
            inter = path.intersection(platform)
            if inter:
                player.point = inter[0]
                player.velocity = Point(0, 0)
                return player


        player.point = path.p2
        player.velocity += delta

        player.point = self.fall_if_need(player.point)
        return player

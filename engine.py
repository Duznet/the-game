from sympy.geometry import Point, Segment
from math import *

class Player:
    DEFAULT_HP = 100

    def __init__(self, point):
        self.point = point
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

    MAX_VELOCITY = 1
    DEFAULT_VELOCITY = 0.1
    SIDE = 0.5
    PLAYER_POS = Point(0.5, 0.5)

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

    def is_on_my_way(start, end, cell):
        path = Polygon(
            Point(start.x, start.y - SIDE),
            Point(start.x, start.y + SIDE),
            Point(end.x, end.y + SIDE),
            Point(end.x, end.y - SIDE))

        cell = Polygon(cell, Point(cell.x, cell.y + 1), cell + Point(1, 1), Point(cell.x + 1, cell.y))

        return path.intersection(cell)


    def cells_path(start, end):
        path = []
        for x in range(floor(start.x), floor(end.x)):
            for y in range(floor(start.y), floor(end.y)):
                if is_on_my_way(start, end, Point(x, y)):
                    path.append(Point(x, y))

        return path

    def players(self):
        players = self.players_order
        for player in players:
            players.point -= Point(1, 1)

        return [self._players[id] for id in players]

    def player_ids(self):
        return self.players_order

    def add_player(self, id):
        self._players[id] = Player(self.spawn + self.PLAYER_POS)
        self.players_order.append(id)
        return self._players[id]

    def move(self, id, dx, dy):
        delta = Point(dx, dy)
        delta /= delta.distance(Point(0, 0))
        player = _players[id]

        path = self.cells_path(player.point, player.point + self.DEFAULT_VELOCITY * delta)

        for id, cell in enumerate(path):
            if self.map[cell.y][cell.x] == self.WALL:
                player.point = path[id - 1] + self.PLAYER_POS
                player.velocity = Point(0, 0)
                return player


        player.point = path.p2
        player.velocity += delta

        return player

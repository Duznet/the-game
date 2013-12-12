import engine

class Collision:
    def __init__(self, time, offset, segment):
        self.time = time
        self.offset = offset
        self.segment = segment

    def __repr__(self):
        return "Collision" + str([self.time, self.offset, self.segment])

class Event:
    def __init__(self, time):
        self.time = time

class WallCollisionEvent(Event):
    def __init__(self, collisions):
        super(WallCollisionEvent, self).__init__(collisions[0].time)
        self.collisions = collisions

    def __repr__(self):
        return str(self.collisions)

    @staticmethod
    def require_event_refresh():
        return True

    def handle(self, player):
        player.point += self.collisions[0].offset
        for collision in self.collisions:
            if engine.utils.is_vertical(collision.segment):
                player.velocity.x = 0
            else:
                player.velocity.y = 0

class TeleportEvent(Event):
    def __init__(self, time, next_point):
        super(TeleportEvent, self).__init__(time)
        self.next_point = next_point

    @staticmethod
    def require_event_refresh():
        return True

    def __repr__(self):
        return "TeleportEvent" + str((self.time, self.next_point))

    def handle(self, player):
        player.point = self.next_point



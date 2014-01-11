class Psg.GameplayConnection extends Psg.Connection

  constructor: (@url) ->
    @ws = new WebSocket @url

    @ws.onopen = =>
      @onopen()

    @ws.onclose = (event) =>
      @onclose event

    onmessage: ->

    @ws.onmessage = (event) =>
      data = JSON.parse event.data
      data.players = data.players.map (p) ->
        t = {}
        t.x = p[0]
        t.y = p[1]
        t.vx = p[2]
        t.vy = p[3]
        t.weapon = p[4]
        t.weaponAngle = p[5]
        t.login = p[6]
        t.health = p[7]
        t.respawn = p[8]
        t.kills = p[9]
        t.deaths = p[10]
        t
      data.projectiles = data.projectiles.map (p) ->
        t = {}
        t.x = p[0]
        t.y = p[1]
        t.vx = p[2]
        t.vy = p[3]
        t.weapon = p[4]
        t.lifeTime = p[5]
        t
      @onmessage data

    @ws.onerror = (error) =>
      @onerror error


  send: (requestData) ->
    @ws.send requestData

  close: ->
    @ws.close()

  move: (sid, tick, dx, dy) ->
    @request "move",
      sid: sid,
      tick: tick,
      dx: dx,
      dy: dy

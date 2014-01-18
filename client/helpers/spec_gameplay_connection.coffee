class Psg.GameplayConnection extends Psg.Connection

  constructor: (@sid, @openDone) ->
    @url = config.gameplayUrl
    @tick = 0

    @ws = new WebSocket @url
    @tick = 0

    @ws.onopen = =>
      console.log '--opening connection--'
      @onopen()
      if @openDone?
        @openDone.resolve()

    @ws.onclose = (event) =>
      console.log '--closing connection--'
      @onclose event


    @ws.onmessage = (event) =>
      data = JSON.parse event.data
      @tick = data.tick
      data.players = data.players.map (p) ->
        t = {}
        t.position = x: p[0], y: p[1]
        t.velocity = x: p[2], y: p[3]
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
        t.position = x: p[0], y: p[1]
        t.velocity = x: p[2], y: p[3]
        t.weapon = p[4]
        t.lifeTime = p[5]
        t
      @onmessage data

    @ws.onerror = (error) =>
      @onerror error


  onopen: (data) ->
    #default placeholder

  onclose: (data) ->
    #default placeholder

  onmessage: (data) ->
    @lostData = data

  onerror: (data) ->
    #default placeholder

  send: (requestData) ->
    @ws.send requestData

  close: ->
    @ws.close()

  move: (dx, dy) ->
    @request "move",
      tick: @tick,
      sid: @sid,
      dx: dx,
      dy: dy

  fire: (dx, dy) ->
    @request "fire",
      tick: @tick,
      sid: @sid,
      dx: dx,
      dy: dy

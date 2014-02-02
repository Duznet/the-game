class Psg.GameplayConnection extends Psg.Connection

  constructor: (attrs) ->
    @url = attrs.url || config.gameplayUrl
    @sid = attrs.sid
    @tick = 0

    @ws = new WebSocket @url
    @ws.onopen = (event) =>
      console.log 'connection opened'
      @onopen event
    @ws.onmessage = (event) =>
      data = JSON.parse event.data
      if data.tick < @tick
        return
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
        t.status = if t.respawn is 0 then 'alive' else 'dead'
        t.statistics = kills: p[9], deaths: p[10]
        return t
      data.projectiles = data.projectiles.map (p) ->
        t = {}
        t.position = x: p[0], y: p[1]
        t.velocity = x: p[2], y: p[3]
        t.weapon = p[4]
        t.lifeTime = p[5]
        return t
      @onmessage data
    @ws.onerror = (event) =>
      @onerror event
    @ws.onclose = (event) =>
      console.log 'connection closed'
      @onclose event

  send: (data) ->
    @ws.send data

  __request__: (action, params) ->
    params = params || {}
    params.tick = @tick
    params.sid = @sid
    @request action, params

  onopen: (data) ->
    #default placeholder

  onclose: (data) ->
    #default placeholder

  onmessage: (data) ->
    #default placeholder

  onerror: (data) ->
    #default placeholder

  close: ->
    @ws.close()

  move: (params) ->
    @__request__ 'move', params

  fire: (params) ->
    @__request__ 'fire', params

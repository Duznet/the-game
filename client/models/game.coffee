class Psg.Game extends Backbone.Model

  initialize: ->
    console.log 'Game initialize'
    @game = @get('user').game

  prepareForUpdate: ->
    for p in @players
      p.status = 'offline'
    @projectiles = []

  updatePlayerData: (data) ->
    login = data[6]
    t = {}
    t.position = x: data[0], y: data[1]
    t.velocity = x: data[2], y: data[3]
    t.weapon = data[4]
    t.weaponAngle = data[5]
    t.health = data[7]
    t.respawn = data[8]
    t.status = if t.respawn is 0 then 'alive' else 'dead'
    t.kdr = kills: data[9], deaths: data[10]
    if not @players[t.login]
      @players[login] = t

  updateProjectileData: (data) ->
    t = {}
    t.position = x: data[0], y: data[1]
    t.velocity = x: data[2], y: data[3]
    t.weapon = data[4]
    t.lifeTime = data[5]
    @projectiles.push t

  startGame: (attrs) ->
    @player = {}
    @player.movement = dx: 0, dy: 0
    @player.fire = dx: 0, dy: 0
    @player.position = x: 0, y: 0

    @players = []
    @projectiles = []
    @items = []

    @gc = new Psg.GameplayConnection sid: @get('user').get('sid')

    @gc.onopen = =>
      @gc.move @player.movement
    @gc.onmessage = (data) =>
      @prepareForUpdate()
      for p in data.players
        @updatePlayerData p
      for login, p of @players
        if p.status is 'offline'
          delete @players[login]
      for p in data.projectiles
        @updateProjectileData p
      @items = data.items

    @sendActionInterval = setInterval =>
      if @player.movement.dx isnt 0 or @player.movement.dy isnt 0
        @gc.move @player.movement
      if @player.fire.dx isnt 0 or @player.fire.dy isnt 0
        @gc.fire @player.fire
    , config.defaultGameConsts.tickSize / 2

    @gc.onclose = =>
      clearInterval @sendActionInterval

  closeConnection: ->
    @gc.close()

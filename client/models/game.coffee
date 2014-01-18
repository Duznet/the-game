class Psg.Game extends Backbone.Model

  initialize: ->
    console.log 'Game initialize'
    @game = @get('user').game

  prepareForUpdate: ->
    for login, p of @players
      p.status = 'offline'
    @projectiles = []

  updatePlayerData: (data) ->
    t = {}
    t.position = x: data[0], y: data[1]
    t.velocity = x: data[2], y: data[3]
    t.weapon = data[4]
    t.weaponAngle = data[5]
    t.login = data[6]
    t.health = data[7]
    t.respawn = data[8]
    t.status = if t.respawn is 0 then 'alive' else 'dead'
    t.statistics = kills: data[9], deaths: data[10]

    if @players[t.login]?
      t.wounded = t.health < @players[t.login].health

    @players[t.login] = t
    if t.login is @get('user').get('login')
      for prop of t
        @player[prop] = t[prop]

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

    @players = {}
    @projectiles = []
    @items = []

    @gc = new Psg.GameplayConnection sid: @get('user').get('sid')

    @gc.onopen = =>
      @projectilesInvalidated = false
      @playersLeft = false
      @gc.move @player.movement
    @gc.onmessage = (data) =>
      @prepareForUpdate()
      for p in data.players
        @updatePlayerData p
      for login, p of @players
        if p.status is 'offline'
          console.log 'player offline'
          delete @players[login]
          @playersLeft = true
      @projectilesInvalidated = true
      for p in data.projectiles
        @updateProjectileData p
      @items = data.items

    @sendActionInterval = setInterval =>
      if @player.movement.dx isnt 0 or @player.movement.dy isnt 0
        @gc.move @player.movement
      if @player.fire.dx isnt 0 or @player.fire.dy isnt 0
        @gc.fire @player.fire
    , config.game.defaultConsts.tickSize / 2

    @gc.onclose = =>
      clearInterval @sendActionInterval

  closeConnection: ->
    @gc.close()

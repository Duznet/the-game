class Psg.Game extends Backbone.Model

  initialize: ->
    console.log 'Game initialize'
    @game = @get('user').game

  prepareForUpdate: ->
    for login, p of @players
      p.status = 'offline'
    @projectiles = []

  updatePlayerData: (playerData) ->
    if @players[playerData.login]?
      playerData.wounded = playerData.health < @players[playerData.login].health
    @players[playerData.login] = playerData
    if playerData.login is @get('user').get('login')
      for prop of playerData
        @player[prop] = playerData[prop]

  updateProjectileData: (projectileData) ->
    @projectiles.push projectileData

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

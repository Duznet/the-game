describe 'Websocket API using server', ->

  @timeout 5000

  hostUser = null
  gc = null
  game = null
  map = null
  tester = new Psg.GameplayTester
  consts = config.game.defaultConsts

  expectedPlayer = null

  checkPlayer = (got, expected = expectedPlayer) ->
    console.log 'checking player'
    for prop of expected
      console.log "#{prop}:"
      console.log 'got: ', got[prop]
      console.log 'expected: ', expected[prop]
      expect(got[prop]).to.almost.eql expected[prop], precision

  maps = [
    {
      name: "Default map"
      maxPlayers: 4
      map: [
        ".............",
        "#..##########",
        "#$..........."
      ]
    },
    {
      name: 'Long line'
      maxPlayers: 4
      map: [
        '...................................................................',
        '...................................................................',
        '...................................................................',
        '...................................................................',
        '.................................$.................................',
      ]
    }
  ]

  findMap = (mapName) ->
    _.find maps, (m) -> m.name is mapName

  precision = Math.round Math.abs Math.log(config.game.defaultConsts.accuracy) / Math.LN10

  before (done) ->
    startTesting ->
      hostUser = gen.getUser()
      hostUser.signup()
      .then ->
        hostUser.signin()
      .then ->
        uploadedCount = 0
        afterMapUpload = ->
          uploadedCount++
          if uploadedCount is maps.length
            hostUser.getMaps().then (data) ->
              maps = data.maps
              done()
        for m in maps
          hostUser.uploadMap(m.name, m.maxPlayers, m.map).then afterMapUpload

  beforeEach (done) ->
    @timeout 5000
    game =
      name: gen.getStr()
      maxPlayers: map.maxPlayers
      map: map.id
    console.log 'game: ', game
    hostUser.createGame(game.name, game.maxPlayers, game.map, config.game.defaultConsts)
    .then ->
      hostUser.getGames()
    .then (data) ->
      game = _.find data.games, (g) -> g.name is game.name
      gc = new Psg.GameplayConnection config.gameplayUrl
      tester.setup gc
      gc.onopen = ->
        gc.move hostUser, 0, 0, 0
        done()

  afterEach (done) ->
    gc.onclose = ->
      hostUser.leaveGame().then ->
        done()

    gc.close()

  describe 'on default map', ->

    before ->
      map = findMap 'Default map'
      console.log 'map is ', map

    it 'should send correct game state', (done) ->

      expectedPlayer =
        position:
          x: 1.5
          y: 2.5
        velocity:
          x: 0
          y: 0
        health: 100

      tester.defineTest ->
        @addCommand ->
          checkPlayer @data.players[0]
          done()

    it 'should move player correctly for one move', (done) ->

      expectedPlayer =
        position:
          x: 1.52
          y: 2.5
        velocity:
          x: 0.02
          y: 0
        health: 100

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 1, 0
        @addCommand ->
          checkPlayer @data.players[0]
          done()

    it 'should not allow player to gain velocity more than maximum value', (done) ->

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 1, 0
        , begin: 0, end: 29
        @addCommand ->
          player = @data.players[0]
          console.log 'player velocity: ', player.velocity
          expect(player.velocity.x).to.almost.equal consts.maxVelocity, precision
        , begin: 20, end: 29
        @addCommand ->
          done()

    it 'should not allow player to move through the wall', (done) ->

      expectedPlayer =
        position:
          x: 1.5
          y: 2.5
        velocity:
          x: 0
          y: 0
        health: 100

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, -1, 0
        @addCommand ->
          checkPlayer @data.players[0]
          done()

    it 'should decrease players velocity if not getting moves', (done) ->

      expectedPlayer =
        position:
          x: 1.5 + 0.02 + 0.04 + 0.02
          y: 2.5
        velocity:
          x: 0.02
          y: 0
        health: 100

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 1, 0
        , end: 1
        @addCommand ->
          console.log 'player velocity: ', @data.players[0].velocity
          gc.move hostUser, 0, 0
        @addCommand ->
          console.log 'player velocity: ', @data.players[0].velocity
          checkPlayer @data.players[0]
          done()

    it 'should stop player if not getting moves', (done) ->

      expectedPlayer =
        position:
          x: 1.52
          y: 2.5
        velocity:
          x: 0
          y: 0
        health: 100

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 1, 0
        @addCommand ->
          gc.move hostUser, 0, 0
        @addCommand ->
          player = @data.players[0]
          gc.move hostUser, 0, 0
          console.log 'player velocity: ', player.velocity
          checkPlayer player
        , end: 10
        @addCommand ->
          done()

    it 'should not allow player to move through the wall after several moves', (done) ->

      expectedPlayer =
        position:
          x: 12.5
          y: 2.5
        velocity:
          x: 0
          y: 0
        health: 100

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 1, 0
        , end: 100
        @addCommand ->
          checkPlayer @data.players[0]
        , begin: 90, end: 100
        @addCommand ->
          done()

    it 'should make player jump correctly', (done) ->

      expectedPlayer =
        position:
          x: 1.5
          y: 2.5 - consts.maxVelocity
        velocity:
          x: 0
          y: -consts.maxVelocity
        health: 100

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 0, -1
        @addCommand ->
          checkPlayer @data.players[0]
          done()

    it 'should make player fall down while jumping', (done) ->

      expectedPlayer =
        position:
          x: 1.5
          y: 2.5 - 3 * consts.maxVelocity + 3 * consts.gravity
        velocity:
          x: 0
          y: -consts.maxVelocity + 2 * consts.gravity
        health: 100

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 0, -1
        , end: 2
        @addCommand ->
          console.log 'player position: ', @data.players[0].position
        , begin: 0, end: 3
        @addCommand ->
          player = @data.players[0]
          checkPlayer @data.players[0]
          done()
        , begin: 3


    it 'should make player fall down to the wall after jumping', (done) ->

      expectedPlayer =
        position:
          x: 1.5
          y: 2.5
        velocity:
          x: 0
          y: 0
        health: 100

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 0, -1
        @addCommand ->
          gc.move hostUser, 0, 0
        , end: 30
        @addCommand ->
          checkPlayer @data.players[0]
          done()

    it 'should lose only vy after with the horizontal part of the wall', (done) ->

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 1, 0
        , end: 20
        @addCommand ->
          gc.move hostUser, 0, -1
        @addCommand ->
          player = @data.players[0]
          expect(player.velocity).to.almost.eql
            x: consts.maxVelocity - consts.friction, y: 0, precision
          done()

    it 'should touch down after continious jump', (done) ->

      @timeout 10000

      touched = false

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 0, -1
        , end: 30
        @addCommand ->
          player = @data.players[0]
          if Math.abs(player.position.y - 2.5) < consts.accuracy
            touched = true
        , begin: 2, end: 30
        @addCommand ->
          expect(touched).to.be.ok
          done()

  describe 'on Long line map', ->

    initialPosition =
      x: 33.5
      y: 4.5

    before ->
      map = findMap 'Long line'
      console.log 'map is ', map

    it 'should jump equal to the right and to the left', (done) ->

      expectedPlayer =
        position: initialPosition

      tester.defineTest ->
        @addCommand ->
          gc.move hostUser, 1, 0
        @addCommand ->
          gc.move hostUser, 1, -1
        @addCommand ->
          gc.move hostUser, 0, 0
        , end: 40
        @addCommand ->
          gc.move hostUser, -1, 0
        @addCommand ->
          gc.move hostUser, -1, -1
        @addCommand ->
          gc.move hostUser, 0, 0
        , end: 80
        @addCommand ->
          checkPlayer @data.players[0]
          done()


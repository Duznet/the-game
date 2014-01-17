describe 'Websocket API using server', ->

  @timeout 5000

  hostUser = null
  gc = null
  game = null
  map = null
  tester = new Psg.GameplayTester
  consts = config.game.defaultConsts

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
    res = _.find maps, (m) -> m.name is mapName
    console.log 'map: ', res
    res

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
    game =
      name: gen.getStr()
      maxPlayers: map.maxPlayers
      map: map.id
    hostUser.createGame(game.name, game.maxPlayers, game.map, config.game.defaultConsts)
    .then ->
      hostUser.getGames()
    .then (data) ->
      game = _.find data.games, (g) -> g.name is game.name
      gc = new Psg.GameplayConnection config.gameplayUrl
      tester.setup gc
      gc.onopen = ->
        gc.move hostUser, 0, 0
        done()

  afterEach (done) ->
    gc.onclose = ->
      hostUser.leaveGame().then ->
        done()

    gc.close()

  describe 'on default map', ->

    before ->
      map = findMap 'Default map'

    it 'should send correct game state', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 1.5
            y: 2.5
          velocity:
            x: 0
            y: 0
        @addCommand ->
          @checkPlayer @data.players[0]
          done()

    it 'should move player correctly for one move', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 1.52
            y: 2.5
          velocity:
            x: 0.02
            y: 0
        @addCommand ->
          gc.move hostUser, 1, 0
        @addCommand ->
          @checkPlayer @data.players[0]
          done()

    it 'should not allow player to gain velocity more than maximum value', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          velocity:
            x: consts.maxVelocity
            y: 0
        @addCommand ->
          gc.move hostUser, 1, 0
        , begin: 0, end: 29
        @addCommand ->
          @checkPlayer @data.players[0]
        , begin: 20, end: 29
        @addCommand ->
          done()

    it 'should not allow player to move through the wall', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 1.5
            y: 2.5
          velocity:
            x: 0
            y: 0
        @addCommand ->
          gc.move hostUser, -1, 0
        @addCommand ->
          @checkPlayer @data.players[0]
          done()

    it 'should decrease players velocity if not getting moves', (done) ->


      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 1.5 + 0.02 + 0.04 + 0.02
            y: 2.5
          velocity:
            x: 0.02
            y: 0
        @addCommand ->
          gc.move hostUser, 1, 0
        , end: 1
        @addCommand ->
          gc.move hostUser, 0, 0
        @addCommand ->
          @checkPlayer @data.players[0]
          done()

    it 'should stop player if not getting moves', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 1.52
            y: 2.5
          velocity:
            x: 0
            y: 0
        @addCommand ->
          gc.move hostUser, 1, 0
        @addCommand ->
          gc.move hostUser, 0, 0
        @addCommand ->
          gc.move hostUser, 0, 0
          @checkPlayer @data.players[0]
        , end: 10
        @addCommand ->
          done()

    it 'should not allow player to move through the wall after several moves', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 12.5
            y: 2.5
          velocity:
            x: 0
            y: 0
        @addCommand ->
          gc.move hostUser, 1, 0
        , end: 100
        @addCommand ->
          @checkPlayer @data.players[0]
        , begin: 90, end: 100
        @addCommand ->
          done()

    it 'should make player jump correctly', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 1.5
            y: 2.5 - consts.maxVelocity
          velocity:
            x: 0
            y: -consts.maxVelocity
        @addCommand ->
          gc.move hostUser, 0, -1
        @addCommand ->
          @checkPlayer @data.players[0]
          done()

    it 'should make player fall down while jumping', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 1.5
            y: 2.5 - 3 * consts.maxVelocity + 3 * consts.gravity
          velocity:
            x: 0
            y: -consts.maxVelocity + 2 * consts.gravity
        @addCommand ->
          gc.move hostUser, 0, -1
        , end: 2
        @addCommand ->
          @checkPlayer @data.players[0]
          done()


    it 'should make player fall down to the wall after jumping', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position:
            x: 1.5
            y: 2.5
          velocity:
            x: 0
            y: 0
          health: 100
        @addCommand ->
          gc.move hostUser, 0, -1
        @addCommand ->
          gc.move hostUser, 0, 0
        , end: 30
        @addCommand ->
          @checkPlayer @data.players[0]
          done()


    it 'should lose only vy after with the horizontal part of the wall', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          velocity:
            x: consts.maxVelocity - consts.friction
            y: 0
        @addCommand ->
          gc.move hostUser, 1, 0
        , end: 20
        @addCommand ->
          gc.move hostUser, 0, -1
        @addCommand ->
          @checkPlayer @data.players[0]
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

    it 'should jump equal to the right and to the left', (done) ->

      tester.defineTest ->
        @expectedPlayer =
          position: initialPosition
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
          @checkPlayer @data.players[0]
          done()


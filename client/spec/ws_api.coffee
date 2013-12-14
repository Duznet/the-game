describe 'Websocket API using server', ->

  hostUser = null
  gc = null
  game = null
  map = null

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
    filteredMaps = maps.filter (m) -> m.name is mapName
    filteredMaps[0]

  precision = Math.round Math.abs Math.log(config.defaultGameConsts.accuracy) / Math.LN10

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
    console.log 'game: ', game
    hostUser.createGame(game.name, game.maxPlayers, game.map)
    .then ->
      hostUser.getGames()
    .then (data) ->
      games = data.games.filter (g) -> g.name is game.name
      game = games[0]
      gc = new Psg.GameplayConnection config.gameplayUrl

      gc.onopen = ->
        gc.move hostUser.sid, 0, 0, 0
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

    it 'should get correct game state every tick', (done) ->

      expectedPlayer =
        x: 1.5
        y: 2.5
        vx: 0
        vy: 0
        hp: 100

      gc.onmessage = (data) ->
        console.log "data: ", data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        expect(data.players[0]).to.almost.eql expectedPlayer, precision
        done()

    it 'should move player correctly for one move', (done) ->

      @timeout 5000

      expectedPlayer =
        x: 1.52
        y: 2.5
        vx: 0.02
        vy: 0
        hp: 100

      count = 0

      gc.onmessage = (data) ->
        count++
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        gc.move hostUser.sid, data.tick, 1, 0
        if count == 2
          expect(data.players[0]).to.almost.eql expectedPlayer, precision
          done()

    it 'should not allow player to gain velocity more than maximum value', (done) ->
      count = 0

      gc.onmessage = (data) ->
        count++
        gc.move(hostUser.sid, data.tick, 1, 0)
        console.log "got: ", data.players[0]
        if count > 10
          player = data.players[0]
          expect(player.vx).to.almost.equal 0.2, precision

        if count == 20
          done()


    it 'should not allow player to move through the wall', (done) ->

      expectedPlayer =
        x: 1.5
        y: 2.5
        vx: 0
        vy: 0
        hp: 100

      count = 0

      gc.onmessage = (data) ->
        count++
        gc.move(hostUser.sid, data.tick, -1, 0)
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        if count == 2
          expect(data.players[0]).to.almost.eql expectedPlayer, precision
          done()

    it 'should decrease players velocity if not getting moves', (done) ->

      expectedPlayer =
        x: 1.5 + 0.02 + 0.04 + 0.02
        y: 2.5
        vx: 0.02
        vy: 0
        hp: 100

      count = 0

      gc.onmessage = (data) ->
        count++
        if count < 3
          gc.move(hostUser.sid, data.tick, 1, 0)
        if count is 3
          gc.move hostUser.sid, data.tick, 0, 0
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        if count == 4
          player = data.players[0]
          console.log "Assert. Expected: ", expectedPlayer, ", got:", player
          expect(data.players[0]).to.almost.eql expectedPlayer, precision
          done()

    it 'should stop player if not getting moves', (done) ->

      expectedPlayer =
        x: 1.52
        y: 2.5
        vx: 0
        vy: 0
        hp: 100

      count = 0

      gc.onmessage = (data) ->
        count++
        if count == 1
          gc.move hostUser.sid, data.tick, 1, 0
        if count is 2
          gc.move hostUser.sid, data.tick, 0, 0
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        if count > 2
          player = data.players[0]
          console.log "Assert. Expected: ", expectedPlayer, ", got:", player
          expect(data.players[0]).to.almost.eql expectedPlayer, precision
          gc.move hostUser.sid, data.tick, 0, 0

        if count == 10
          done()

    it 'should not allow player to move through the wall after several moves', (done) ->

      expectedPlayer =
        x: 12.5
        y: 2.5
        vx: 0
        vy: 0
        hp: 100

      count = 0
      @timeout 5000

      gc.onmessage = (data) ->
        count++
        gc.move(hostUser.sid, data.tick, 1, 0)
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        if count > 90
          player = data.players[0]
          expect(data.players[0]).to.almost.eql expectedPlayer, precision
        if count == 100
          done()

    it 'should make player jump correctly', (done) ->

      expectedPlayer =
        x: 1.5
        y: 2.5 - 0.2
        vx: 0
        vy: -0.2
        hp: 100

      count = 0

      gc.onmessage = (data) ->
        count++
        gc.move(hostUser.sid, data.tick, 0, -1)
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        if count == 2
          expect(data.players[0]).to.almost.eql expectedPlayer, precision
          done()

    it 'should make player fall down while jumping', (done) ->

      expectedPlayer =
        x: 1.5
        y: 2.5 - 0.2 - 0.2 + 0.02
        vx: 0
        vy: -0.2 + 0.02
        hp: 100

      count = 0

      gc.onmessage = (data) ->
        count++
        gc.move(hostUser.sid, data.tick, 0, -1)
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        console.log "count: ", count
        if count == 3
          player = data.players[0]
          console.log "Assert. Expected: ", expectedPlayer, ", got:", player
          expect(data.players[0]).to.almost.eql expectedPlayer, precision
          done()

    it 'should make player fall down to the wall after jumping', (done) ->

      expectedPlayer =
        x: 1.5
        y: 2.5
        vx: 0
        vy: 0
        hp: 100

      count = 0

      gc.onmessage = (data) ->
        count++
        if count == 40
          done()

        if count == 1
          gc.move hostUser.sid, data.tick, 0, -1
        if 1 < count < 31
          gc.move hostUser.sid, data.tick, 0, 0
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        console.log "count: ", count
        if count > 30
          player = data.players[0]
          console.log "Assert. Expected: ", expectedPlayer, ", got:", player
          expect(data.players[0]).to.almost.eql expectedPlayer, precision
          gc.move hostUser.sid, data.tick, 0, 0


    it 'should loose only vy after with the horizontal part of the wall', (done) ->
      @timeout 5000

      count = 0

      gc.onmessage = (data) ->
        count++
        if count < 20
          gc.move(hostUser.sid, data.tick, 1, 0)

        if count == 20
          gc.move(hostUser.sid, data.tick, 0, 1)

        console.log "got: ", data.players[0]
        if count == 21
          player = data.players[0]

          expect(player.vy).to.almost.equal 0, precision
          expect(player.vx).to.almost.equal 0.18, precision
          done()

    it 'should touch down after continious jump', (done) ->
      @timeout 10000

      count = 0

      touched = false

      gc.onmessage = (data) ->
        count++
        player = data.players[0]
        console.log "got: ", data.players[0]
        if count < 30
          gc.move(hostUser.sid, data.tick, 0, -1)
        if count > 2 and Math.abs(player.y - 2.5) < config.defaultGameConsts.accuracy
          touched = true

        if count is 30
          console.log "count is 30; player: ", data.players[0]
          expect(touched).to.be.ok
          done()

  describe 'on Long line map', ->

    @timeout 5000

    initialPosition =
      x: 33.5
      y: 4.5


    before ->
      map = findMap 'Long line'
      console.log 'map is ', map

    it 'should change only vy on diagonal jumping to the right', (done) ->

      expectedPosition =
        x: initialPosition.x + 2 * config.defaultGameConsts.accel + 2 * 20 * config.defaultGameConsts.accel
        y: initialPosition.y

      count = 0

      gc.onmessage = (data) ->
        count++
        console.log 'player: ', data.players[0]
        player = data.players[0]
        if count is 1
          gc.move(hostUser.sid, data.tick, 1, 0)
        else if count is 2
          gc.move(hostUser.sid, data.tick, 1, -1)
        else if count is 3
          gc.move(hostUser.sid, data.tick, 0, -1)
        else if count is 30
          playerPosition =
            x: data.players[0].x
            y: data.players[0].y
          console.log 'count is 30; player position: ', playerPosition
          expect(playerPosition).to.almost.eql expectedPosition, precision
          done()
        else
          gc.move(hostUser.sid, data.tick, 0, 0)

    it 'should change only vy on diagonal jumping to the left', (done) ->

      expectedPosition =
        x: initialPosition.x - 2 * config.defaultGameConsts.accel - 2 * 20 * config.defaultGameConsts.accel
        y: initialPosition.y

      count = 0

      gc.onmessage = (data) ->
        count++
        console.log 'player: ', data.players[0]
        player = data.players[0]
        if count is 1
          gc.move(hostUser.sid, data.tick, -1, 0)
        else if count is 2
          gc.move(hostUser.sid, data.tick, -1, -1)
        else if count is 3
          gc.move(hostUser.sid, data.tick, 0, -1)
        else if count is 30
          playerPosition =
            x: data.players[0].x
            y: data.players[0].y
          console.log 'count is 30; player position: ', playerPosition
          expect(playerPosition).to.almost.eql expectedPosition, precision
          done()
        else
          gc.move(hostUser.sid, data.tick, 0, 0)

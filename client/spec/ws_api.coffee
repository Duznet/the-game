describe 'Websocket API using server', ->

  hostUser = null
  gc = null
  game = null
  map = null
  maps = null

  precision = Math.round Math.abs Math.log(config.defaultGameConsts.accuracy) / Math.LN10

  before (done) ->
    startTesting done

  beforeEach (done) ->
    hostUser = gen.getUser()
    game =
      name: gen.getStr()
      maxPlayers: 2

    map =
      name: gen.getStr()
      maxPlayers: 4
      map: [".............",
            "#..##########",
            "#$..........."]

    teleport_map =
      name: gen.getStr()
      maxPlayers: 2
      map: ['.1.',
            '.##',
            '$1.']

    hostUser.signup()
    .then ->
      hostUser.signin()
    .then ->
      hostUser.uploadMap map.name, map.maxPlayers, map.map
    .then ->
      hostUser.getMaps()
    .then (data) ->
      for m in data.maps
        if m.name is map.name
          map = m
          break
      game.map = map.id
      hostUser.createGame game.name, game.maxPlayers, game.map
    .then ->
      hostUser.getGames()
    .then (data) ->
      for g in data.games
        if g.name is game.name
          game = g
      gc = new Psg.GameplayConnection config.gameplayUrl

      gc.onopen = ->
        gc.move hostUser.sid, 0, 0, 0
        done()

  afterEach (done) ->
    gc.close()
    gc.onclose = ->
      hostUser.leaveGame()
      .then ->
        done()

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
        expect(player.vx).to.almost.equal 0.2, precision
        done()

  it 'should touch down after continious jump', (done) ->
    @timeout 5000

    count = 0

    touched = false

    gc.onmessage = (data) ->
      count++
      player = data.players[0]
      if count < 20
        gc.move(hostUser.sid, data.tick, 0, -1)
      if count > 2 and Math.abs(player.y - 2.5) < config.defaultGameConsts.accuracy
        touched = true

      if count is 20
        expect(touched).to.be.ok
        done()

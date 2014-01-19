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
    },
    {
      name: 'map-with-platform'
      maxPlayers: 4
      map: [
        '..................................',
        '..................................',
        '..................................',
        '...###############################',
        '$.................................',
      ]
    },
    {
      name: 'teleport-map'
      maxPlayers: 4
      map: [
        '2.......$...1.',
        '#############.',
        '3.4#1.35.2#6.5',
        '##############',
        '..6......4....',
      ]
    },
    {
      name: 'hole-map'
      maxPlayers: 4
      map: [
        '..............',
        '#.####........',
        '#.#..#........',
        '#.#..#........',
        '#.#..#........',
        '..............',
        '#$.#.#.#.$....',
      ]
    },
    {
      name: 'respawn-map'
      maxPlayers: 12
      map: [
        '........................',
        '...$.................$..',
        '..#####...........#####.',
        '............$...........',
        '..........#####.........',
        '.$..............$......$',
        '.######......######..###',
        '............$...........',
        '.......########.........',
      ]
    },
    {
      name: 'weapons-map'
      maxPlayers: 12
      map: [
        '...................',
        '...................',
        '...................',
        '$..A..R..M..P..K...',
      ]
    },
    {
      name: 'small-duel-arena'
      maxPlayers: 12
      map: [
        '.............................................',
        '.............................................',
        '.............................................',
        '.............................................',
        '.............................................',
        '......P..M..A..R...$.h...K...$......$....$...',
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
      gc = new Psg.GameplayConnection hostUser.sid
      tester.setup gc
      gc.onopen = ->
        gc.move 0, 0
        done()

  afterEach (done) ->
    gc.onclose = ->
      hostUser.leaveGame().then ->
        if tester.users.length > 0
          tester.leaveGame(0, 1).then ->
            done()
        else
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
          gc.move 1, 0
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
          gc.move 1, 0
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
          gc.move -1, 0
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
          gc.move 1, 0
        , end: 1
        @addCommand ->
          gc.move 0, 0
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
          gc.move 1, 0
        @addCommand ->
          gc.move 0, 0
        @addCommand ->
          gc.move 0, 0
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
          gc.move 1, 0
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
          gc.move 0, -1
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
          gc.move 0, -1
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
          gc.move 0, -1
        @addCommand ->
          gc.move 0, 0
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
          gc.move 1, 0
        , end: 20
        @addCommand ->
          gc.move 0, -1
        @addCommand ->
          @checkPlayer @data.players[0]
          done()

    it 'should touch down after continious jump', (done) ->

      @timeout 10000

      touched = false

      tester.defineTest ->
        @addCommand ->
          gc.move 0, -1
        , end: 30
        @addCommand ->
          player = @data.players[0]
          if Math.abs(player.position.y - 2.5) < consts.accuracy
            touched = true
        , begin: 2, end: 30
        @addCommand ->
          expect(touched).to.be.ok
          done()

  describe 'on map with platform', ->
    initPos =
      x: 0
      y: 4.5

    before ->
      map = findMap 'map-with-platform'

    it 'should jump onto the platform after right-top jump', (done) ->
      tester.addUser gen.getUser(), game.id
      tester.addUser gen.getUser(), game.id

      tester.defineTest ->
        @expectedPlayer =
          position: initPos

        @addCommand ->
          gc.move 0, -1
          for user in @users
            user.gc.move 0, 0
        @addCommand ->
          gc.move 1, 0
          for user in @users
            user.gc.move 0, 0
        , end: 40
        @addCommand ->
          got = @data.players[0].position
          expect(got.x).to.be.greaterThan initPos.x + 3
          expect(got.y).to.almost.equal initPos.y - 2, @precision
          done()

  describe 'on Long line map', ->

    initPos =
      x: 33.5
      y: 4.5

    before ->
      map = findMap 'Long line'

    it 'should jump equal to the right and to the left', (done) ->
      tester.defineTest ->
        @expectedPlayer =
          position: initPos
        @addCommand ->
          gc.move 1, 0
        @addCommand ->
          gc.move 1, -1
        @addCommand ->
          gc.move 0, 0
        , end: 40
        @addCommand ->
          gc.move -1, 0
        @addCommand ->
          gc.move -1, -1
        @addCommand ->
          gc.move 0, 0
        , end: 80
        @addCommand ->
          @checkPlayer @data.players[0]
          done()

  describe 'on teleport map', ->
    initPos =
      x: 8.5
      y: 0.5

    before ->
      map = findMap 'teleport-map'

    it 'should run to the end', (done) ->
      tester.addUser gen.getUser(), game.id
      tester.defineTest ->
        @expectedPlayerRight  =
          position:
            x: 13.5
            y: 4.5
        @expectedPlayerLeft  =
          position:
            x: 0.5
            y: 4.5
        @addCommand ->
          gc.move 0, 0
          for user in @users
            user.gc.move 0, 0
        , end: 3

        @addCommand ->
          gc.move 1, 0
          @users[0].gc.move -1, 0
        , end: 50

        @addCommand ->
          @checkPlayer @data.players[0], @expectedPlayerRight
          @checkPlayer @data.players[1], @expectedPlayerLeft

          done()

    it 'shouldn\'t lose velocity while teleporting', (done) ->
      tester.addUser gen.getUser(), game.id
      tester.defineTest ->
        @addCommand ->
          gc.move 1, 0
          @users[0].gc.move -1, 0
        , end: 20

        @addCommand ->
          @v = @data.players[0].velocity
        , begin: 18

        @addCommand ->
          expect(@data.players[0].velocity.x).to.be.greaterThan @v.x
          @checkPlayer @data.players[0],
            position:
              x: 4.5
              y: 2.5

          done()
        , begin: 19

    it 'should pass all teleports', (done) ->
      tester.addUser gen.getUser(), game.id
      tester.defineTest ->
        @addCommand ->
          gc.move 1, 0
          @users[0].gc.move -1, 0
        , end: 50

        @addCommand ->
          @checkPlayer @data.players[0],
            position:
              x: 4.5
              y: 2.5

        , begin: 19

        @addCommand ->
          @checkPlayer @data.players[0],
            position:
              x: 0.5
              y: 2.5

        , begin: 23

        @addCommand ->
          @checkPlayer @data.players[0],
            position:
              x: 9.5
              y: 4.5

        , begin: 27

        @addCommand ->
          @checkPlayer @data.players[1],
            position:
              x: 13.5
              y: 2.5

        , begin: 33


        @addCommand ->
          @checkPlayer @data.players[1],
            position:
              x: 2.5
              y: 4.5

          done()

        , begin: 37

  describe 'on hole map', ->
    initPos =
      x: 1.5
      y: 6.5

    before ->
      map = findMap 'hole-map'

    it 'should pass into the upper hole', (done) ->
      tester.addUser gen.getUser(), game.id

      tester.defineTest ->
        @addCommand ->
          gc.move 0, -1
          @users[0].gc.move -1, -1

        @addCommand ->
          gc.move 0, 0
          @users[0].gc.move -1, 0
        , end: 20

        @addCommand ->
          gc.move 0, 0
          @users[0].gc.move 0, 0
        , end: 50

        @addCommand ->
          player = @data.players[0]
          expect(player.position.x).to.almost.equal initPos.x
          expect(player.position.y).to.be.lessThan 5
        , begin: 8

        @addCommand ->
          @checkPlayer @data.players[1],
            position:
              x: 6.5
              y: 6.5

          done()
        , begin: 50

  describe 'on respawn map', ->

    initPos =
      x: 3.5
      y: 1.5

    before ->
      map = findMap 'respawn-map'

    it 'should place players on correct respawns', (done) ->

      for i in [0..6]
        tester.addUser gen.getUser(), game.id

      expectedPositions = [
        { x: 3.5, y: 1.5 },
        { x: 21.5, y: 1.5 },
        { x: 12.5, y: 3.5 },
        { x: 1.5, y: 5.5 },
        { x: 16.5, y: 5.5 },
        { x: 23.5, y: 5.5 },
        { x: 12.5, y: 7.5 },
        { x: 3.5, y: 1.5 }
      ]

      tester.defineTest ->
        @addCommand ->
          gc.move 0, 0
          for u in @users
            u.gc.move 0, 0
        @addCommand ->
          for p, i in @data.players
            @checkPlayer p, position: expectedPositions[i]
          done()

  describe 'on weapons map', ->
      initPos =
        x: 0.5
        y: 3.5

      before ->
        map = findMap 'weapons-map'

      it 'should allow player to pick up a rail gun', (done) ->

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'A'
          @addCommand ->
            gc.move 1, 0
          , end: 12
          @addCommand ->
            gc.move 0, 1
          , end: 25
          @addCommand ->
            @checkPlayer @data.players[0]
            done()

      it 'should allow player to fire with rail gun', (done) ->

        tester.defineTest ->
          @expectedProjectile =
            weapon: 'A'
            lifeTime: 1
          @addCommand ->
            gc.move 1, 0
          , end: 12
          @addCommand ->
            gc.move 0, 1
          , end: 25
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            @checkProjectile @data.projectiles[0]
            expect(@data.projectiles.length).to.be.equal 1
            done()

      it 'should allow player to pick up a rocket launcher', (done) ->

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'R'
          @addCommand ->
            gc.move 1, 0
          , end: 20
          @addCommand ->
            gc.move 0, 1
          , end: 40
          @addCommand ->
            @checkPlayer @data.players[0]
            done()

      it 'should allow player to fire with a rocket launcher', (done) ->

        tester.defineTest ->
          @expectedProjectile =
            weapon: 'R'
            lifeTime: 1
          @addCommand ->
            gc.move 1, 0
          , end: 20
          @addCommand ->
            gc.move 0, 1
          , end: 40
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            @checkProjectile @data.projectiles[0]
            expect(@data.projectiles.length).to.be.equal 1
            done()

      it 'should allow player to pick up a machine gun', (done) ->

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'M'
          @addCommand ->
            gc.move 1, 0
          , end: 25
          @addCommand ->
            gc.move 0, 1
          , end: 45
          @addCommand ->
            @checkPlayer @data.players[0]
            done()

      it 'should allow player to fire with machine gun', (done) ->

        tester.defineTest ->
          @expectedProjectile =
            weapon: 'M'
            lifeTime: 1
          @addCommand ->
            gc.move 1, 0
          , end: 25
          @addCommand ->
            gc.move 0, 1
          , end: 45
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            @checkProjectile @data.projectiles[0]
            expect(@data.projectiles.length).to.be.equal 1
            done()

      it 'should allow player to pick up a pistol', (done) ->

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'P'
          @addCommand ->
            gc.move 1, 0
          , end: 33
          @addCommand ->
            gc.move 0, 1
          , end: 50
          @addCommand ->
            @checkPlayer @data.players[0]
            done()

      it 'should allow player to fire with a pistol', (done) ->

        tester.defineTest ->
          @expectedProjectile =
            weapon: 'P'
            lifeTime: 1
          @addCommand ->
            gc.move 1, 0
          , end: 33
          @addCommand ->
            gc.move 0, 1
          , end: 50
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            @checkProjectile @data.projectiles[0]
            expect(@data.projectiles.length).to.be.equal 1
            done()

      it 'should allow player to pick up a knife', (done) ->

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'K'
          @addCommand ->
            gc.move 1, 0
          , end: 45
          @addCommand ->
            gc.move 0, 1
          , end: 65
          @addCommand ->
            @checkPlayer @data.players[0]
            done()

      it 'should allow player to \'fire\' with a knife', (done) ->

        tester.defineTest ->
          @expectedProjectile =
            weapon: 'K'
            lifeTime: 1
          @addCommand ->
            gc.move 1, 0
          , end: 45
          @addCommand ->
            gc.move 0, 1
          , end: 65
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            @checkProjectile @data.projectiles[0]
            expect(@data.projectiles.length).to.be.equal 1
            done()

    describe 'on small duel arena map', ->

      @timeout 10000

      initPos =
        x: 19.5
        y: 5.5

      before ->
        map = findMap 'small-duel-arena'


      it 'should allow player to injury himself with rocket burst', (done) ->

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'R'
            health: 100
          @addCommand ->
            gc.move -1, 0
          , end: 15
          @addCommand ->
            gc.move 0, 0
          , end: 35
          @addCommand ->
            gc.fire 0, 1
          @addCommand ->
            expect(@data.players[0].health).to.be.lessThan 100
            done()

      it 'should allow player to pick up health', (done) ->

        health = 100
        pickedUpHealth = false

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'R'
            health: 100
          @addCommand ->
            gc.move -1, 0
          , end: 15
          @addCommand ->
            gc.move 0, 0
          , end: 35
          @addCommand ->
            gc.fire 0, 1
          @addCommand ->
            gc.move 0, 0
            health = @data.players[0].health
          , end: 80
          @addCommand ->
            gc.move 1, 0
          , end: 105
          @addCommand ->
            gc.move 0, 0
            if @data.players[0].health > health
              pickedUpHealth = true
          , end: 130
          @addCommand ->
            expect(pickedUpHealth).to.be.ok
            done()

      it 'should allow player to injury other player with rocket launcher', (done) ->

        tester.addUser gen.getUser(), game.id

        injuried = false

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'R'
            health: 100
          @addCommand ->
            for user in @users
              user.gc.move 0, 0
          , end: 100
          @addCommand ->
            gc.move -1, 0
          , begin: 0, end: 15
          @addCommand ->
            gc.move 0, 0
          , end: 35
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            gc.move 0, 0
            if @data.players[1].health < 100
              injuried = true
          , end: 70
          @addCommand ->
            expect(injuried).to.be.ok
            done()


      it 'should allow player to injury other players with rail gun', (done) ->

        tester.addUser gen.getUser(), game.id
        tester.addUser gen.getUser(), game.id

        injuried = false

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'A'
            health: 100
          @addCommand ->
            for user in @users
              user.gc.move 0, 0
          , end: 100
          @addCommand ->
            gc.move -1, 0
          , begin: 0, end: 20
          @addCommand ->
            gc.move 0, 0
          , end: 40
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            gc.move 0, 0
            if @data.players[1].health < 100 and @data.players[2].health < 100
              injuried = true
          , end: 60
          @addCommand ->
            expect(injuried).to.be.ok
            done()

      it 'should allow player to injury other player with machine gun', (done) ->

        tester.addUser gen.getUser(), game.id

        injuried = false

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'M'
            health: 100
          @expectedProjectile =
            weapon: 'M'
          @addCommand ->
            for user in @users
              user.gc.move 0, 0
          , end: 100
          @addCommand ->
            gc.move -1, 0
          , begin: 0, end: 25
          @addCommand ->
            gc.move 0, 0
          , end: 35
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            gc.move 0, 0
            if @data.players[1].health < 100
              injuried = true
          , end: 65
          @addCommand ->
            expect(injuried).to.be.ok
            done()

      it 'should allow player to injury other player with pistol', (done) ->

        tester.addUser gen.getUser(), game.id

        injuried = false

        tester.defineTest ->
          @expectedPlayer =
            weapon: 'P'
            health: 100
          @expectedProjectile =
            weapon: 'P'
          @addCommand ->
            for user in @users
              user.gc.move 0, 0
          , end: 100
          @addCommand ->
            gc.move -1, 0
          , begin: 0, end: 35
          @addCommand ->
            gc.move 0, 0
          , end: 50
          @addCommand ->
            gc.fire 1, 0
          @addCommand ->
            gc.move 0, 0
            if @data.players[1].health < 100
              injuried = true
          , end: 80
          @addCommand ->
            expect(injuried).to.be.ok
            done()




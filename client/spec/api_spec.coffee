expect = chai.expect

describe 'API using server', ->

  conn = new GameConnector(config.gameUrl)
  gen = new Generator
  before (done) ->
    conn.startTesting().then done()

  it 'should respond with Object containing string field "result"', (done) ->
    conn.send('some string').then (data) ->
      expect(data).to.be.an('Object')
      expect(data).to.contain.keys('result')
      expect(data.result).to.be.a('String')
      done()

  it 'should respond with "badJSON" if it received one brace', (done) ->
    conn.send("{").then (data) ->
      expect(data.result).to.equal "badJSON"
      done()

  it 'should respond with "badJSON" if it received incorrect json string', (done) ->
    conn.send("suddenly string").then (data) ->
      expect(data.result).to.equal "badJSON"
      done()

  it 'should respond with "badRequest" if it received only json string', (done) ->
    conn.send('"suddenly string"').then (data) ->
      expect(data.result).to.equal "badRequest"
      done()

  it 'should respond with "badRequest" if it got array instead of params object', (done) ->
    conn.request("signup", [1, 2, 3]).then (data) ->
      expect(data.result).to.equal "badRequest"
      done()

  it 'should respond with "badAction" if it could not recognize action', (done) ->
    conn.request(gen.getStr(), {}).then (data) ->
      expect(data.result).to.equal "badAction"
      done()

  it 'should respond with "badAction" if the action field was empty', (done) ->
    conn.request("", login: gen.getLogin()).then (data) ->
      expect(data.result).to.equal "badAction"
      done()


  describe 'on Auth', ->

    describe '#signup', ->

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("signup", login: gen.getLogin()).then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should allow user to sign up using login and password', (done) ->
        user = gen.getUser()
        conn.signup(user.login, user.password).then (data) ->
          expect(data.result).to.equal "ok"
          done()

      it 'should respond with "userExists" if this user already existed', (done) ->
        user = gen.getUser()
        conn.signup(user.login, user.password)
        .then ->
          conn.signup(user.login, user.password)
        .then (data) ->
          expect(data.result).to.equal "userExists"
          done()

      it 'should respond with "badLogin" if login was shorter than 4 symbols', (done) ->
        conn.signup("1", gen.getPassword()).then (data) ->
          expect(data.result).to.equal "badLogin"
          done()

      it 'should respond with "badLogin" if login was longer than 40 symbols', (done) ->
        conn.signup(gen.getLogin("veryveryveryveryveryveryveryveryverylong"), gen.getPassword())
        .then (data) ->
          expect(data.result).to.equal "badLogin"
          done()

      it 'should respond with "badPassword" if password was shorter than 4 symbols', (done) ->
        conn.signup(gen.getLogin(), "1").then (data) ->
          expect(data.result).to.equal "badPassword"
          done()

      it 'should respond with "badLogin" or "badPassword" if login and password were incorrect', (done) ->
        conn.signup("sh", "sh").then (data) ->
          expect(data.result).to.match /badPassword|badLogin/
          done()


    describe '#signin', ->

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("signin", login: gen.getLogin()).then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should respond with sid after the correct signin request', (done) ->
        user = gen.getUser()
        user.signup()
        .then ->
          conn.signin(user.login, user.password)
        .then (data) ->
          expect(data.result).to.equal "ok"
          expect(data.sid).to.match /^[a-zA-z0-9]+$/
          done()

      it 'should respond with "incorrect" if user with requested login did not exist', (done) ->
        user = gen.getUser()
        user.signup()
        .then ->
          conn.signin(user.login + 'no', user.password)
        .then (data) ->
          expect(data.result).to.equal "incorrect"
          done()

      it 'should respond with "incorrect" if login and password did not match', (done) ->
        user = gen.getUser()
        user.signup()
        .then ->
          conn.signin(user.login, user.password + 'no')
        .then (data) ->
          expect(data.result).to.equal "incorrect"
          done()

      it 'should respond with "incorrect" if login was empty', (done) ->
        conn.signin("", gen.getPassword()).then (data) ->
          expect(data.result).to.equal "incorrect"
          done()

      it 'should respond with "incorrect" if login was too long', (done) ->
        conn.signin(gen.getLogin("veryveryveryveryveryveryveryveryverylong"),
            gen.getPassword()).then (data) ->
          expect(data.result).to.equal "incorrect"
          done()

      it 'should respond with "badLogin" if login was not correct string', (done) ->
        conn.signin(prop: "haha", gen.getPassword()).then (data) ->
          expect(data.result).to.equal "badLogin"
          done()

      it 'should respond with "incorrect" if password was too short', (done) ->
        conn.signin(gen.getLogin(), "s").then (data) ->
          expect(data.result).to.equal "incorrect"
          done()

      it 'should respond with "badPassword" if password was not correct string', (done) ->
        conn.signin(gen.getLogin(), id: 31415).then (data) ->
          expect(data.result).to.equal "badPassword"
          done()


    describe '#signout', ->

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("signout").then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should allow user to sign out using the sid', (done) ->
        user = gen.getUser()
        user.signup()
        .then ->
          user.signin()
        .then ->
          conn.signout(user.sid)
        .then (data) ->
          expect(data.result).to.equal "ok"
          done()

      it 'should respond with "badSid" if sid was empty', (done) ->
        conn.signout("").then (data) ->
          expect(data.result).to.equal "badSid"
          done()

      it 'should respond with "badSid" if sid could not be found', (done) ->
        conn.signout("sidNotFound123").then (data) ->
          expect(data.result).to.equal "badSid"
          done()

      it 'should respond with "badSid" if user has already signed out', (done) ->
        oldSid = ""
        user = gen.getUser()
        user.signup()
        .then ->
          user.signin()
        .then ->
           oldSid = user.sid
           user.signout()
        .then ->
          conn.signout(oldSid)
        .then (data) ->
          expect(data.result).to.equal "badSid"
          done()


  describe 'on Messages', ->

    user = gen.getUser()

    before (done) ->
      user.signup()
      .then ->
        user.signin()
      .then ->
        done()

    describe '#sendMessage', ->

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("sendMessage", sid: user.sid).then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should allow users to send text to the global chat using sid', (done) ->
        conn.sendMessage(user.sid, "", "Hello").then (data) ->
          expect(data.result).to.equal "ok"
          done()

      it 'should respond with "badSid" if user with that sid was not found', (done) ->
        conn.sendMessage("^&%DF&TSDFH", "", "Hello").then (data) ->
          expect(data.result).to.equal "badSid"
          done()

      it 'should respond with "badGame" if it received string value in game field instead of number', (done) ->
        conn.sendMessage(user.sid, "Scaarface", "I always tell the truth. Even when I lie").then (data) ->
          expect(data.result).to.equal "badGame"
          done()

      it 'should respond with "badText" if it received an array instead of string value in text field', (done) ->
        conn.sendMessage(user.sid, "", [1, 2, 12]).then (data) ->
          expect(data.result).to.equal "badText"
          done()

      describe 'after joining into game', ->

        gameCreator = gen.getUser()
        anotherGameCreator = gen.getUser()
        joinedUser = gen.getUser()

        map = null
        game = null
        anotherGame = null

        mapName = gen.getStr()
        gameName = gen.getStr()
        anotherGameName = gen.getStr()

        before (done) ->
          $.when(gameCreator.signup(), anotherGameCreator.signup(), joinedUser.signup())
          .then ->
            $.when(gameCreator.signin(), anotherGameCreator.signin(), joinedUser.signin())
          .then ->
            gameCreator.uploadMap(mapName, 16, ['...', '.$.', '###'])
          .then ->
            gameCreator.getMaps()
          .then (data) ->
            for curMap in data.maps
              if curMap.name is mapName
                map = curMap
                break
            $.when(gameCreator.createGame(gameName, map.maxPlayers, map.id),
                anotherGameCreator.createGame(anotherGameName, map.maxPlayers, map.id))
          .then ->
            joinedUser.getGames()
          .then (data) ->
            for curGame in data.games
              if curGame.name is gameName
                game = curGame
              else if curGame.name is anotherGameName
                anotherGame = curGame
            joinedUser.joinGame(game.id)
          .then (data) ->
            if data.result is "ok"
              done()

        it 'should allow game creator to send Messages into the global chat', (done) ->
          conn.sendMessage(gameCreator.sid, "", gen.getStr()).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow game guest to send messages into the global chat', (done) ->
          conn.sendMessage(joinedUser.sid, "", gen.getStr()).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with "badGame" if game creator was trying to send message to another in-game chat', (done) ->
          conn.sendMessage(gameCreator.sid, anotherGame.id, gen.getStr()).then (data) ->
            expect(data.result).to.equal "badGame"
            done()

        it 'should respond with "badGame" if game guest was trying to send message to another in-game chat', (done) ->
          conn.sendMessage(joinedUser.sid, anotherGame.id, gen.getStr()).then (data) ->
            expect(data.result).to.equal "badGame"
            done()


    describe '#getMessages', ->

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("getMessages", sid: user.sid).then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should respond with "badSid" if user with that sid was not found', (done) ->
        conn.getMessages(user.sid + "#W*&^W#$", "", 0).then (data) ->
          expect(data.result).to.equal "badSid"
          done()

      it 'should respond with "badGame" if it received string game id instead of number', (done) ->
        conn.getMessages(user.sid, "#$(*&", 0).then (data) ->
          expect(data.result).to.equal "badGame"
          done()

      it 'should respond with "badSince" if the "since" timestamp was not correct', (done) ->
        conn.getMessages(user.sid, "", "suddenly not correct time").then (data) ->
          expect(data.result).to.equal "badSince"
          done()

      describe 'after some messages sending', ->

        messagesCount = 30
        messages = []
        users = []

        messageContent = (login, game, text) -> "#{login}::#{game}::#{text}"

        before (done) ->
          completedCount = 0

          wait = ->
            if completedCount is messagesCount
              done()

          users[0] = user
          user[1] = gen.getUser()
          user.signup()
          .then ->
            user.signin()
          .then ->
            for i in [0...messagesCount]
              text = gen.getStr()
              messages[i] = messageContent users[i % users.length].login, "", text
              conn.sendMessage(users[i % users.length].sid, "", text).then ->
                completedCount += 1
                wait()

        it 'should allow user to execute getMessages using sid', (done) ->
          conn.getMessages(user.sid, "", 0).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with array containing all sent messages', (done) ->
          conn.getMessages(user.sid, "", 0).then (data) ->
            expect(data.messages).to.have.length.of.at.least messagesCount
            messagesGot = data.messages.map (message) -> messageContent message.login, "", message.text
            for m in messages
              expect(messagesGot).to.contain m
            done()

        it 'should respond with array containing messages ordered by time', (done) ->
          conn.getMessages(user.sid, "", 0).then (data) ->
            curTime = 0
            for m in data.messages
              expect(m.time).to.be.at.least curTime
              curTime = m.time
            done()

        it 'should respond with array containing messages received on server later than time parameter', (done) ->
          firstLength = 0
          time = 0
          conn.getMessages(user.sid, "", 0)
          .then (data) ->
            firstLength = data.messages.length
            time = data.messages[Math.floor data.messages.length / 2].time
            conn.getMessages(user.sid, "", time)
          .then (data) ->
            for m in data.messages
              expect(m.time).to.be.at.least time
            done()

      describe 'after joining into game', ->

        gameCreator = gen.getUser()
        anotherGameCreator = gen.getUser()
        joinedUser = gen.getUser()

        map = null
        game = null
        anotherGame = null

        mapName = gen.getStr()
        gameName = gen.getStr()
        anotherGameName = gen.getStr()

        before (done) ->
          $.when(gameCreator.signup(), anotherGameCreator.signup(), joinedUser.signup())
          .then ->
            $.when(gameCreator.signin(), anotherGameCreator.signin(), joinedUser.signin())
          .then ->
            gameCreator.uploadMap(mapName, 16, ['...', '.$.', '###'])
          .then ->
            gameCreator.getMaps()
          .then (data) ->
            for curMap in data.maps
              if curMap.name is mapName
                map = curMap
                break
            $.when(gameCreator.createGame(gameName, map.maxPlayers, map.id),
                anotherGameCreator.createGame(anotherGameName, map.maxPlayers, map.id))
          .then ->
            joinedUser.getGames()
          .then (data) ->
            for curGame in data.games
              if curGame.name is gameName
                game = curGame
              else if curGame.name is anotherGameName
                anotherGame = curGame
            joinedUser.joinGame(game.id)
          .then (data) ->
            if data.result is "ok"
              done()

        it 'should allow game creator to send Messages into the global chat', (done) ->
          conn.getMessages(gameCreator.sid, "", 0).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow game guest to send messages into the global chat', (done) ->
          conn.getMessages(joinedUser.sid, "", 0).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with "badGame" if game creator was trying to send message to another in-game chat', (done) ->
          conn.getMessages(gameCreator.sid, anotherGame.id, 0).then (data) ->
            expect(data.result).to.equal "badGame"
            done()

        it 'should respond with "badGame" if game guest was trying to send message to another in-game chat', (done) ->
          conn.getMessages(joinedUser.sid, anotherGame.id, 0).then (data) ->
            expect(data.result).to.equal "badGame"
            done()


  describe 'on Maps', ->

    describe '#uploadMap', (done) ->

      user = gen.getUser()

      before (done) ->
        user.signup()
        .then ->
          user.signin()
        .then ->
          done()

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("uploadMap", sid: user.sid).then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should allow users to create maps', (done) ->
        conn.uploadMap(user.sid, gen.getStr(), 16, ["."]).then (data) ->
          expect(data.result).to.equal "ok"
          done()

      it 'should respond with "badSid" if user with that sid was not found', (done) ->
        conn.uploadMap("#{user.sid}@#&*^@#$!}}", 10, ["."]).then (data) ->
          expect(data.result).to.equal "badSid"
          done()

      it 'should respond with "badName" if map name was empty', (done) ->
        conn.uploadMap(user.sid, "", 10, ["."]).then (data) ->
          expect(data.result).to.equal "badName"
          done()

      it 'should respond with "badMaxPlayers" if maxPlayers field was empty', (done) ->
        conn.uploadMap(user.sid, gen.getStr(), "", ["."]).then (data) ->
          expect(data.result).to.equal "badMaxPlayers"
          done()

      it 'should respond with "badMap" if row lengths are not equal', (done) ->
        conn.uploadMap(user.sid, gen.getStr(), 16, ["...", "..", "..."]).then (data) ->
          expect(data.result).to.equal "badMap"
          done()


    describe '#getMaps', ->

      user = gen.getUser()
      map =
        name: gen.getStr()
        maxPlayers: 4
        map: ["...", "...", "..."]

      before (done) ->
        user.signup()
        .then ->
          user.signin()
        .then ->
          user.uploadMap map.name, map.maxPlayers, map.map
        .then ->
          done()

      it 'should allow users to execute getMaps action using the correct sid', (done) ->
        conn.getMaps(user.sid).then (data) ->
          expect(data.result).to.equal "ok"
          done()

      it 'should allow users to get map list containing uploaded map', (done) ->
        conn.getMaps(user.sid).then (data) ->
          expect(data.maps.length).to.be.above 0
          uploadedMapFoundCount = 0
          for m in data.maps
            if m.name is map.name
              uploadedMapFoundCount += 1
              expect(m.map).to.eql map.map
              expect(m.maxPlayers).to.equal map.maxPlayers
          expect(uploadedMapFoundCount).to.equal 1
          done()

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("getMaps", {}).then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should respond with "badSid" if user with that sid was not found', (done) ->
        conn.getMaps("#{user.sid}$#%").then (data) ->
          expect(data.result).to.equal "badSid"
          done()

  ###describe 'Game controlling', ->
    hostUser =
      login: "host_user"
      password: "host_pass"

    joiningUser =
      login: "joiner_login"
      password: "joiner_pass"

    maps = []
    map = []
    map2 = []

    beforeEach ->
      signup hostUser.login, hostUser.password
      signup joiningUser.login, joiningUser.password
      hostUser.sid = signin(hostUser.login, hostUser.password).sid
      joiningUser.sid = signin(joiningUser.login, joiningUser.password).sid
      uploadMap hostUser.sid, "testMap", 4, ["..", "$."]
      uploadMap hostUser.sid, "testMap2", 4, ["."]
      maps = getMaps(hostUser.sid).maps
      map = maps[0]
      map2 = maps[1]

    describe 'createGame action', ->
      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("createGame", sid: hostUser.sid).result).to.equal "paramMissed"

      it 'should allow users to create games', ->
        expect(createGame(hostUser.sid, map.name + "Game", map.id, map.maxPlayers).result).to.equal "ok"

      it 'should respond with "gameExists" if game with requested name already exists', ->
        gameName = "gameNumber1"
        expect(createGame(hostUser.sid, gameName, map.id, map.maxPlayers).result).to.equal "ok"
        expect(createGame(joiningUser.sid, gameName, map2.id, map2.maxPlayers).result).to.equal "gameExists"

      it 'should respond with "badName" if game name was empty', ->
        expect(createGame(hostUser.sid, "", map.id, map.maxPlayers).result).to.equal "badName"

      it 'should respond with "badMap" if map with that id was not found', ->
        expect(createGame(hostUser.sid, "badMapGame", map.id + "@#$@#$", map.maxPlayers).result).to.equal "badMap"

      it 'should respond with "badMap" if requested map id was empty', ->
        expect(createGame(hostUser.sid, "emptyMapNameGame", "", map.maxPlayers).result).to.equal "badMap"

      it 'should respond with "badMaxPlayers" if maxPlayers field was empty', ->
        expect(createGame(hostUser.sid, "badMaxPlayersGame", map.id, "").result).to.equal "badMaxPlayers"

      it 'should respond with "badMaxPlayers" if maxPlayers field was not like correct number', ->
        expect(createGame(hostUser.sid, "badMaxPlayersNaNGame", map.id, "suddenly!").result).to.equal "badMaxPlayers"

      it 'should respond with "alreadyInGame" if host user was trying to create two games simultaneously', ->
        expect(createGame(hostUser.sid, "AlreadyInGameGame1", map.id, map.maxPlayers).result).to.equal "ok"
        expect(createGame(hostUser.sid, "AlreadyInGameGame2", map2.id, map.maxPlayers).result).to.equal "alreadyInGame"


    describe 'getGames action', ->
      game =
        name: "getGamesTest"
        map: map.id
        maxPlayers: map.maxPlayers

      beforeEach ->
        leaveGame hostUser.sid
        leaveGame joiningUser.sid
        createGame hostUser.sid, game.name, game.map, game.maxPlayers

      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("getGames", {}).result).to.equal "paramMissed"

      it 'should allow users to get game list', ->
        getGamesResponse = getGames(joiningUser.sid)
        expect(getGamesResponse.result).to.equal "ok"
        expect(getGamesResponse.games).to.not.be.undefined
        i = 0

        while i < getGamesResponse.games.length
          if getGamesResponse.games[i].name is game.name
            cur = getGamesResponse.games[i]
            expect(cur.map).to.equal game.map
            expect(cur.maxPlayers).to.equal game.maxPlayers
            expect(cur.players.length).to.equal 1
            expect(cur.players[0]).to.equal hostUser.login

          i++

      it "should respond with object containing players array sorted by join time", ->
        games = getGames(joiningUser.sid).games
        for g in games
          if g.name is game.name
            game.id = g.id
            break
        joinGame joiningUser.sid, game.id
        getGamesResponse = getGames joiningUser.sid
        expect(getGamesResponse.result).to.equal "ok"
        expect(getGamesResponse.games).to.not.be.undefined
        i = 0
        while i < getGamesResponse.games.length
          if getGamesResponse.games[i].name is game.name
            cur = getGamesResponse.games[i]
            expect(cur.map).to.equal game.map
            expect(cur.maxPlayers).to.equal game.maxPlayers
            expect(cur.players.length).to.equal 2
            expect(cur.players[0]).to.equal hostUser.login
            expect(cur.players[1]).to.equal joiningUser.login

          i++

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(getGames(joiningUser.sid + "#(&@(&@$").result).to.equal "badSid"


    describe 'joinGame action', ->
      gameCreator =
        login: "gameCreator"
        password: "hosterPass"


      game =
        name: "joinGameTest"
        maxPlayers: 2

      games = []

      beforeEach ->
        game.map = map.id
        signup gameCreator.login, gameCreator.password
        gameCreator.sid = signin(gameCreator.login, gameCreator.password).sid
        createGame gameCreator.sid, game.name, game.map, game.maxPlayers
        games = getGames(joiningUser.sid).games
        game = games[0]


      it 'should allow users to join game using the sid and game id', ->
        expect(joinGame(joiningUser.sid, game.id).result).to.equal "ok"

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(joinGame(joiningUser.sid + "#@(*#q", game.id).result).to.equal "badSid"

      it 'should respond with "badGame" if game id was like some string', ->
        expect(joinGame(joiningUser.sid, game.id + "#@(&").result).to.equal "badGame"

      it 'should respond with "badGame" if game id was empty', ->
        expect(joinGame(joiningUser.sid, "").result).to.equal "badGame"

      it 'should respond with "badGame" if game id was empty', ->
        expect(joinGame(joiningUser.sid, "").result).to.equal "badGame"

      it 'should respond with "gameFull" if max players amount was reached', ->
        expect(joinGame(joiningUser.sid, game.id).result).to.equal "ok"
        oddManOut =
          login: "oddLogin"
          password: "oddPassword"

        signup oddManOut.login, oddManOut.password
        oddManOut.sid = signin(oddManOut.login, oddManOut.password).sid
        expect(joinGame(oddManOut.sid, game.id).result).to.equal "gameFull"


    describe 'leaveGame action', ->
      game =
        name: "leaveGameTest"
        maxPlayers: 3

      beforeEach ->
        game.map = map.id
        createGame hostUser.sid, game.name, game.map, game.maxPlayers

      it 'should respond with "paramMissed if it did not receive all required params ', ->
        expect(getResponse("leaveGame", {}).result).to.equal "paramMissed"

      it 'should allow host users to leave created games', ->
        expect(leaveGame(hostUser.sid).result).to.equal "ok"

      it 'should respond with "notInGame" if user trying to leave game was not in any', ->
        expect(leaveGame(joiningUser.sid).result).to.equal "notInGame"

      it 'should respong with "badSid" if user with that sid was not found', ->
        expect(leaveGame(joiningUser.sid + "@#$@#$").result).to.equal "badSid"


  describe 'Websocket controlling', ->

    hostUser =
      login: "hostUser"
      password: "hostUser"

    game =
      name: "joinGameTest"
      maxPlayers: 2

    map =
      name: "testmap"
      maxPlayers: 4
      map: ["..", "$."]

    websocket = {}

    beforeEach (done) ->
      signup hostUser.login, hostUser.password
      hostUser.sid = signin(hostUser.login, hostUser.password).sid

      uploadMap hostUser.sid, map.name, map.maxPlayers, map.map
      maps = getMaps(hostUser.sid).maps
      map = maps[0]

      game.map = map.id
      createGame hostUser.sid, game.name, game.map, game.maxPlayers
      games = getGames(hostUser.sid).games
      game = games[0]

      websocket = new WebSocket config.gameplayUrl
      websocket.onopen = (event) ->
        move(websocket, hostUser.sid, 0, 0, 0)
        done()

    afterEach ->
      websocket.close()

    it 'should get correct game state every tick', (done) ->
      expectedPlayer =
        x: 0.5
        y: 1.5
        vx: 0
        vy: 0
        hp: 100

      websocket.onmessage = (event) ->
        console.log event.data
        expect(JSON.parse(event.data).players[0]).to.eql expectedPlayer
        done()

    it 'should move players correctly for one move', (done) ->
      expectedPlayer =
        x: 0.6
        y: 1.5
        vx: 0.1
        vy: 0
        hp: 100

      count = 0

      data = {}
      websocket.onmessage = (event) ->
        count++
        console.log event.data
        data = JSON.parse(event.data)
        move(websocket, hostUser.sid, data.tick, 1, 0)
        if count == 2
          player = data.players[0]
          for key of player
            player[key] = parseFloat(player[key].toFixed(6))

          expect(data.players[0]).to.eql expectedPlayer
          done()
###

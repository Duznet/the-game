expect = chai.expect

describe 'API using server', ->

  conn = new GameConnector(config.gameUrl)
  gen = new Generator

  before (done) ->
    conn.startTesting(config.websocketMode).then (data) ->
      if data.result isnt "ok"
        throw new Error('Could not start testing')
      done()

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

      user = null

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("signin", login: gen.getLogin()).then (data) ->
          expect(data.result).to.equal "badRequest"
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

      describe 'after signup', ->

        beforeEach (done) ->
          user = gen.getUser()
          user.signup()
          .then ->
            done()

        it 'should respond with sid after the correct signin request', (done) ->
          conn.signin(user.login, user.password)
          .then (data) ->
            expect(data.result).to.equal "ok"
            expect(data.sid).to.match /^[a-zA-z0-9]+$/
            done()

        it 'should respond with "incorrect" if user with requested login did not exist', (done) ->
          conn.signin(user.login + 'no', user.password)
          .then (data) ->
            expect(data.result).to.equal "incorrect"
            done()

        it 'should respond with "incorrect" if login and password did not match', (done) ->
          conn.signin(user.login, user.password + 'no')
          .then (data) ->
            expect(data.result).to.equal "incorrect"
            done()

        it 'should allow user to signin when user has already signed in', (done) ->
          conn.signin(user.login, user.password)
          .then ->
            conn.signin(user.login, user.password)
          .then (data) ->
            expect(data.result).to.equal "ok"
            done()


    describe '#signout', ->

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("signout").then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should respond with "badSid" if sid was empty', (done) ->
        conn.signout("").then (data) ->
          expect(data.result).to.equal "badSid"
          done()

      it 'should respond with "badSid" if sid could not be found', (done) ->
        conn.signout("sidNotFound123").then (data) ->
          expect(data.result).to.equal "badSid"
          done()

      it 'should respond with "badSid" if sid contained invalid symbols', (done) ->
        conn.signout("@{$@#$").then (data) ->
          expect(data.result).to.equal "badSid"
          done()

      describe 'after signin', ->

        user = null

        beforeEach (done) ->
          user = gen.getUser()
          user.signup()
          .then ->
            user.signin()
          .then ->
            done()

        it 'should allow user to sign out using the sid', (done) ->
          conn.signout(user.sid)
          .then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with "badSid" if user has already signed out', (done) ->
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
        gameGuest = gen.getUser()

        map = null
        game = null
        anotherGame = null

        mapName = gen.getStr()
        gameName = gen.getStr()
        anotherGameName = gen.getStr()

        before (done) ->
          $.when(gameCreator.signup(), anotherGameCreator.signup(), gameGuest.signup())
          .then ->
            $.when(gameCreator.signin(), anotherGameCreator.signin(), gameGuest.signin())
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
            gameGuest.getGames()
          .then (data) ->
            for curGame in data.games
              if curGame.name is gameName
                game = curGame
              else if curGame.name is anotherGameName
                anotherGame = curGame
            gameGuest.joinGame(game.id)
          .then (data) ->
            if data.result is "ok"
              done()

        it 'should allow game creator to send messages into the global chat', (done) ->
          conn.sendMessage(gameCreator.sid, "", gen.getStr()).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow game guest to send messages into the global chat', (done) ->
          conn.sendMessage(gameGuest.sid, "", gen.getStr()).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow game creator to send messages into the in-game chat', (done) ->
          conn.sendMessage(gameCreator.sid, game.id, gen.getStr()).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow game guest to send messages into the in-game chat', (done) ->
          conn.sendMessage(gameGuest.sid, game.id, gen.getStr()).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with "badGame" if game creator was trying to send message to another in-game chat', (done) ->
          conn.sendMessage(gameCreator.sid, anotherGame.id, gen.getStr()).then (data) ->
            expect(data.result).to.equal "badGame"
            done()

        it 'should respond with "badGame" if game guest was trying to send message to another in-game chat', (done) ->
          conn.sendMessage(gameGuest.sid, anotherGame.id, gen.getStr()).then (data) ->
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
          users[1] = gen.getUser()
          users[1].signup()
          .then ->
            users[1].signin()
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
        gameGuest = gen.getUser()

        map = null
        game = null
        anotherGame = null

        mapName = gen.getStr()
        gameName = gen.getStr()
        anotherGameName = gen.getStr()

        before (done) ->
          $.when(gameCreator.signup(), anotherGameCreator.signup(), gameGuest.signup())
          .then ->
            $.when(gameCreator.signin(), anotherGameCreator.signin(), gameGuest.signin())
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
            gameGuest.getGames()
          .then (data) ->
            for curGame in data.games
              if curGame.name is gameName
                game = curGame
              else if curGame.name is anotherGameName
                anotherGame = curGame
            gameGuest.joinGame(game.id)
          .then (data) ->
            if data.result is "ok"
              done()

        it 'should allow game creator to get messages from the global chat', (done) ->
          conn.getMessages(gameCreator.sid, "", 0).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow game guest to get messages from the global chat', (done) ->
          conn.getMessages(gameGuest.sid, "", 0).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow game creator to get messages from the in-game chat', (done) ->
          conn.getMessages(gameCreator.sid, game.id, 0).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow game guest to get messages from the in-game chat', (done) ->
          conn.getMessages(gameGuest.sid, game.id, 0).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with "badGame" if game creator was trying to get messages from another in-game chat', (done) ->
          conn.getMessages(gameCreator.sid, anotherGame.id, 0).then (data) ->
            expect(data.result).to.equal "badGame"
            done()

        it 'should respond with "badGame" if game guest was trying to get messages from another in-game chat', (done) ->
          conn.getMessages(gameGuest.sid, anotherGame.id, 0).then (data) ->
            expect(data.result).to.equal "badGame"
            done()


  describe 'on Maps', ->

    describe '#uploadMap', ->

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

      it 'should respond with "badMap" if it has one teleport without exit', (done) ->
        conn.uploadMap(user.sid, gen.getStr(), 16, ["1..", ".$."]).then (data) ->
          expect(data.result).to.equal "badMap"
          done()

      it 'should respond with "badMap" if it has more than two teleports marked with one number', (done) ->
        conn.uploadMap(user.sid, gen.getStr(), 16, ["1.1", ".1.", "###"]).then (data) ->
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


  describe 'on Games', ->

    gameCreator = gen.getUser()
    mapName = gen.getStr()
    map = null

    before (done) ->
      gameCreator.signup()
      .then ->
        gameCreator.signin()
      .then ->
        gameCreator.uploadMap(mapName, 4, ["..", "$."])
      .then ->
        gameCreator.getMaps()
      .then (data) ->
        maps = data.maps.filter (m) -> m.name is mapName
        map = maps[0]
        done()

    describe '#createGame', ->

      afterEach (done) ->
        gameCreator.leaveGame()
        .then ->
          done()

      it 'should respond with "badRequest" if it did not receive all required params', (done) ->
        conn.request("createGame", sid: gameCreator.sid).then (data) ->
          expect(data.result).to.equal "badRequest"
          done()

      it 'should respond with "badMap" if requested map id was empty', (done) ->
        conn.createGame(gameCreator.sid, gen.getStr(), 2, "").then (data) ->
          expect(data.result).to.equal "badMap"
          done()

      it 'should respond with "badMap" if map id was not integer', (done) ->
        conn.createGame(
            gameCreator.sid, gen.getStr(), map.maxPlayers, "#{map.id}@#$@#$").then (data) ->
          expect(data.result).to.equal "badMap"
          done()

      it 'should respond with "badMap" if map id could not be found', (done) ->
        conn.createGame(
            gameCreator.sid, gen.getStr(), map.maxPlayers, map.id + 200000).then (data) ->
          expect(data.result).to.equal "badMap"
          done()

      it 'should allow users to create games', (done) ->
        conn.createGame(gameCreator.sid, gen.getStr(), map.maxPlayers, map.id).then (data) ->
          expect(data.result).to.equal "ok"
          done()

      it 'should respond with "badName" if game name was empty', (done) ->
        conn.createGame(gameCreator.sid, "", map.maxPlayers, map.id).then (data) ->
          expect(data.result).to.equal "badName"
          done()

      it 'should respond with "badMaxPlayers" if maxPlayers field was empty string', (done) ->
        conn.createGame(gameCreator.sid, gen.getStr(), "", map.id).then (data) ->
          expect(data.result).to.equal "badMaxPlayers"
          done()

      it 'should respond with "badMaxPlayers" if maxPlayers field was not like correct number', (done) ->
        conn.createGame(gameCreator.sid, gen.getStr(), "suddenly string", map.id).then (data) ->
          expect(data.result).to.equal "badMaxPlayers"
          done()

      it 'should respond with "badMaxPlayers" if maxPlayers of the game is greater than map allows', (done) ->
        conn.createGame(gameCreator.sid, gen.getStr(), map.maxPlayers + 1, map.id).then (data) ->
          expect(data.result).to.equal "badMaxPlayers"
          done()

      it 'should respond with "alreadyInGame" if host user was trying to create two games simultaneously', (done) ->
        conn.createGame(gameCreator.sid, gen.getStr(), map.maxPlayers, map.id)
        .then ->
          conn.createGame(gameCreator.sid, gen.getStr(), map.maxPlayers, map.id)
        .then (data) ->
          expect(data.result).to.equal "alreadyInGame"
          done()

      describe 'after another player singing in', ->

        anotherMap = null
        anotherGameCreator = null
        anotherMapName = null
        gameName = null

        before (done) ->
          anotherGameCreator = gen.getUser()
          anotherMapName = gen.getStr()

          anotherGameCreator.signup()
          .then ->
            anotherGameCreator.signin()
          .then ->
            anotherGameCreator.uploadMap(anotherMapName, 2, ["......", "####$$"])
          .then (data) ->
            anotherGameCreator.getMaps()
          .then (data) ->
            maps = data.maps.filter (m) -> m.name is anotherMapName
            anotherMap = maps[0]
            done()

        afterEach (done) ->
          anotherGameCreator.leaveGame()
          .then ->
            done()

        it 'should allow users to create games on one map', (done) ->
          conn.createGame(gameCreator.sid, gen.getStr(), map.maxPlayers, map.id)
          .then ->
            conn.createGame(anotherGameCreator.sid, gen.getStr(), map.maxPlayers, map.id)
          .then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with "gameExists" if game with requested name already exists', (done) ->
          gameName = gen.getStr()
          conn.createGame(gameCreator.sid, gameName, map.maxPlayers, map.id)
          .then ->
            conn.createGame(anotherGameCreator.sid, gameName, anotherMap.maxPlayers, anotherMap.id)
          .then (data) ->
            expect(data.result).to.equal "gameExists"
            done()


    describe 'after game creation', ->

      gameName = gen.getStr()
      gameGuest = gen.getUser()

      findGame = (games, name) ->
        (games.filter (g) -> g.name is name)[0]

      before (done) ->
        gameGuest.signup()
        .then ->
          $.when(gameGuest.signin(), gameCreator.createGame(gameName, map.maxPlayers, map.id))
        .then ->
          done()

      afterEach (done) ->
        gameGuest.leaveGame()
        .then ->
          done()

      describe '#getGames', ->

        it 'should respond with "badRequest" if it did not receive all required params', (done) ->
          conn.request("getGames").then (data) ->
            expect(data.result).to.equal "badRequest"
            done()

        it 'should allow in-game users to get game list', (done) ->
          conn.getGames(gameCreator.sid).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should allow not-in-game users to get game list', (done) ->
          conn.getGames(gameGuest.sid).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with list of games containing recently created game', (done) ->
          conn.getGames(gameGuest.sid).then (data) ->
            games = data.games.filter (g) -> g.name is gameName
            expect(games.length).to.equal 1
            curGame = games[0]
            expect(curGame.maxPlayers).to.equal map.maxPlayers
            expect(curGame.map).to.equal map.id
            expect(curGame.players.length).to.equal 1
            done()

        it "should respond with object containing players array sorted by join time", (done) ->

          conn.getGames(gameGuest.sid)
          .then (data) ->
            curGame = findGame data.games, gameName
            gameGuest.joinGame(curGame.id)
          .then ->
            conn.getGames(gameGuest.sid)
          .then (data) ->
            curGame = findGame data.games, gameName
            expect(curGame.players.length).to.equal 2
            expect(curGame.players[0]).to.equal gameCreator.login
            expect(curGame.players[1]).to.equal gameGuest.login
            done()

        it 'should respond with "badSid" if user with that sid was not found', (done) ->
          conn.getGames("#{gameGuest.sid}#(&@(&@$").then (data) ->
            expect(data.result).to.equal "badSid"
            done()


      describe '#joinGame', ->

        game = null

        before (done) ->
          gameGuest.getGames()
          .then (data) ->
            game = findGame(data.games, gameName)
            done()

        it 'should respond with "badRequest" if it did not receive all required params', (done) ->
          conn.request("joinGame").then (data) ->
            expect(data.result).to.equal "badRequest"
            done()

        it 'should allow users to join game using the sid and game id', (done) ->
          conn.joinGame(gameGuest.sid, game.id).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with "badSid" if user with that sid was not found', (done) ->
          conn.joinGame("#{gameGuest.sid}ab123", game.id).then (data) ->
            expect(data.result).to.equal "badSid"
            done()

        it 'should respond with "badGame" if game id could not be found', (done) ->
          conn.joinGame(gameGuest.sid, "#{game.id}12").then (data) ->
            expect(data.result).to.equal "badGame"
            done()

        it 'should respond with "badGame" if game id was empty', (done) ->
          conn.joinGame(gameGuest.sid, "").then (data) ->
            expect(data.result).to.equal "badGame"
            done()

        describe 'after filling in game', ->

          guests = [gameCreator]

          before (done) ->
            @timeout 5000
            count = 0

            addGuest = ->
              if count is game.maxPlayers - 1
                done()
              else
                g = gen.getUser()
                g.signup()
                .then ->
                  g.signin()
                .then ->
                  g.joinGame(game.id)
                .then (data) ->
                  if data.result is "ok"
                    count++
                    guests.push g
                    addGuest()
                  else
                    console.log data.result

            addGuest()

          it 'should respond with "gameFull" if max players amount was reached', (done) ->

            oddManOut = gen.getUser()
            oddManOut.signup()
            .then ->
              oddManOut.signin()
            .then ->
              conn.joinGame(oddManOut.sid, game.id)
            .then (data) ->
              expect(data.result).to.equal "gameFull"
              done()


      describe '#leaveGame', ->

        game = null

        beforeEach (done) ->
          gameCreator.createGame(gameName, map.maxPlayers, map.id)
          .then ->
            gameGuest.getGames()
          .then (data) ->
            game = findGame(data.games, gameName)
            done()

        it 'should respond with "badRequest if it did not receive all required params ', (done) ->
          conn.request("leaveGame").then (data) ->
            expect(data.result).to.equal "badRequest"
            done()

        it 'should allow host users to leave created games', (done) ->
          conn.leaveGame(gameCreator.sid).then (data) ->
            expect(data.result).to.equal "ok"
            done()

        it 'should respond with "notInGame" if user trying to leave game was not in any', (done) ->
          conn.leaveGame(gameGuest.sid).then (data) ->
            expect(data.result).to.equal "notInGame"
            done()

        it 'should respong with "badSid" if user with that sid was not found', (done) ->
          conn.leaveGame("#a{gameGuest.sid}asd1").then (data) ->
            expect(data.result).to.equal "badSid"
            done()


  describe 'on Websocket', ->

    hostUser = null
    gc = null
    game = null
    map = null
    maps = null

    precision = Math.round Math.abs Math.log(config.defaultGameConsts.accuracy) / Math.LN10

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
        gc = new GameplayConnector config.gameplayUrl

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
          gc.move(hostUser.sid, data.tick, 1, 0)
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        if count > 2
          player = data.players[0]
          console.log "Assert. Expected: ", expectedPlayer, ", got:", player
          expect(data.players[0]).to.almost.eql expectedPlayer, precision

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
        if count == 1
          gc.move(hostUser.sid, data.tick, 0, -1)
        console.log data
        console.log "expected: ", expectedPlayer
        console.log "got: ", data.players[0]
        console.log "count: ", count
        if count > 30
          player = data.players[0]
          console.log "Assert. Expected: ", expectedPlayer, ", got:", player
          expect(data.players[0]).to.almost.eql expectedPlayer, precision

        if count == 40
          done()

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

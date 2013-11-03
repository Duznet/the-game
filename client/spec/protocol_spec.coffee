expect = chai.expect

describe 'Protocol supporting server', ->
  conn = new GameConnector(config.gameUrl)
  testingStarted = false
  before (done) ->
    conn.startTesting().then done()

  it 'should respond with Object', (done) ->
    conn.send('some string').then (data) ->
      expect(data).to.be.an('Object')
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

  it 'should respond with "unknownAction" if it could not recognize action', (done) ->
    conn.request("asdkhasdasd", {}).then (data) ->
      expect(data.result).to.equal "unknownAction"
      done()

  it 'should respond with "unknownAction" if the action field was empty', (done) ->
    conn.request("", params: login: "some_login").then (data) ->
      expect(data.result).to.equal "unknownAction"
      done()

  describe 'signup action', ->
    it 'should respond with "badRequest" if it did not receive all required params', (done) ->
      conn.request("signup", login: "some_login").then (data) ->
        expect(data.result).to.equal "badRequest"
        done()

    it 'should allow user to sign up using login and password', (done) ->
      conn.signup("signup_test_login", "signup_test_pass").then (data) ->
        expect(data.result).to.equal "ok"
        done()

    it 'should respond with "userExists" if this user already existed', (done) ->
      conn.signup("existing_user", "existing_password")
      .then ->
        conn.signup("existing_user", "existing_password2")
      .then (data) ->
        expect(data.result).to.equal "userExists"
        done()

    it 'should respond with "badLogin" if login was shorter than 4 symbols', (done) ->
      conn.signup("1", "short_test_password").then (data) ->
        expect(data.result).to.equal "badLogin"
        done()

    it 'should respond with "badLogin" if login was longer than 40 symbols', (done) ->
      conn.signup("abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqrstuvwxyz", "long_test_password")
      .then (data) ->
        expect(data.result).to.equal "badLogin"
        done()

    it 'should respond with "badPassword" if password was shorter than 4 symbols', (done) ->
      conn.signup("short_pass_login", "1").then (data) ->
        expect(data.result).to.equal "badPassword"
        done()

    it 'should respond with "badLogin" or "badPassword" if login and password were incorrect', (done) ->
      conn.signup("sh", "sh").then (data) ->
        expect(data.result).to.match /badPassword|badLogin/
        done()

  describe 'signin action', ->
    it 'should respond with "paramMissed" if it did not receive all required params', ->
      expect(getResponse("signin", login: "some_login").result).to.equal "paramMissed"
      expect(getResponse("signin", param: "some_password").result).to.equal "paramMissed"

    it 'should respond with sid after the correct signin request', ->
      userLogin = "signin_test_login"
      userPass = "signin_test_pass"
      expect(signup(userLogin, userPass).result).to.equal "ok"
      got = signin(userLogin, userPass)
      expect(got.result).to.equal "ok"
      expect(got.sid).to.not.be.undefined
      expect(got.sid).to.match /^[a-zA-z0-9]+$/

    it 'should respond with "incorrect" if user with requested login did not exist', ->
      userLogin = "signin_incorrect_l_test_login"
      userPass = "signin_incorrect_l_test_pass"
      expect(signup(userLogin, userPass).result).to.equal "ok"
      expect(signin(userLogin + "no", userPass).result).to.equal "incorrect"
      expect(signin(userLogin, userPass + "no").result).to.equal "incorrect"

    it 'should respond with "incorrect" if login and password did not match', ->
      userLogin = "signin_incorrect_p_test_login"
      userPass = "signin_incorrect_p_test_pass"
      expect(signup(userLogin, userPass).result).to.equal "ok"
      expect(signin(userLogin, userPass + "no").result).to.equal "incorrect"

    it 'should respond with "incorrect" if login was empty', ->
      expect(signin("", "123").result).to.equal "incorrect"


  describe 'signout action', ->
    it 'should respond with "paramMissed" if it did not receive all required params', ->
      expect(getResponse("signout", {}).result).to.equal "paramMissed"

    it 'should allow user to sign out using the sid', ->
      userLogin = "signout_test_login"
      userPassword = "singout_test_pass"
      expect(signup(userLogin, userPassword).result).to.equal "ok"
      signinResponse = signin(userLogin, userPassword)
      expect(signinResponse.result).to.equal "ok"
      expect(signout(signinResponse.sid).result).to.equal "ok"

    it 'should respond with "badSid" if sid was empty', ->
      expect(signout("").result).to.equal "badSid"

    it 'should respond with "badSid" if sid could not be found', ->
      expect(signout("sidNotFound123").result).to.equal "badSid"

    it 'should respond with "badSid" if user was not signed in', ->
      userLogin = "singed_out_user"
      userPassword = "signed_out_pass"
      signup userLogin, userPassword
      sid = signin(userLogin, userPassword).sid
      expect(signout(sid).result).to.equal "ok"
      expect(signout(sid).result).to.equal "badSid"


  describe 'Messages', ->
    firstUser =
      login: "mess_test_login1"
      password: "mess_test_pass1"

    secondUser =
      login: "mess_test_login2"
      password: "mess_test_pass2"

    beforeEach ->
      signup firstUser.login, firstUser.password
      signup secondUser.login, secondUser.password
      firstUser.sid = signin(firstUser.login, firstUser.password).sid
      secondUser.sid = signin(secondUser.login, secondUser.password).sid

    describe 'sendMessage action', ->
      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("sendMessage", {sid: firstUser.sid, game: ""}).result).to.equal "paramMissed"
        expect(getResponse("sendMessage", {sid: firstUser.sid, text: "some text"}).result).to.equal "paramMissed"
        expect(getResponse("sendMessage", {game: "", text: "some text"}).result).to.equal "paramMissed"

      it 'should allow user to send text to chat using sid', ->
        expect(sendMessage(firstUser.sid, "", "Hello").result).to.equal "ok"

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(sendMessage("^&%DF&TSDFH", "", "Hello").result).to.equal "badSid"


    describe 'getMessages action', ->
      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("getMessages", sid: firstUser.sid).result).to.equal "paramMissed"

      it 'should allow user to get messages using sid', ->
        firstText = "Hello, second"
        secondText = "Hi, first"
        expect(sendMessage(firstUser.sid, "", firstText).result).to.equal "ok"
        expect(sendMessage(secondUser.sid, "", secondText).result).to.equal "ok"
        getMessagesResponse = getMessages(firstUser.sid, "", 0)
        expect(getMessagesResponse.result).to.equal "ok"
        firstMessage = getMessagesResponse.messages[getMessagesResponse.messages.length - 2]
        secondMessage = getMessagesResponse.messages[getMessagesResponse.messages.length - 1]
        expect(secondMessage.time).to.be.above firstMessage.time
        firstAuthor = (if firstMessage.login is firstUser.login then firstUser else secondUser)
        secondAuthor = (if secondMessage.login is secondUser.login then secondUser else firstUser)
        expect(firstMessage.login).to.equal firstAuthor.login
        expect(firstMessage.text).to.equal firstText
        expect(secondMessage.login).to.equal secondAuthor.login
        expect(secondMessage.text).to.equal secondText

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(getMessages(firstUser.sid + "#W*&^W#$", "", 0).result).to.equal "badSid"

      it 'should respond with "badGame" if game with that id was not found', ->
        expect(getMessages(firstUser.sid, "#$(*&", 0).result).to.equal "badGame"

      it 'should respond with "badSince" if the "since" timestamp was not cool', ->
        expect(getMessages(firstUser.sid, "", "suddenly not time").result).to.equal "badSince"



  describe 'Map controlling', ->
    describe 'uploadMap action', ->
      user =
        login: "mapUploaderLogin"
        password: "mapUploaderPass"

      beforeEach ->
        signup user.login, user.password
        user.sid = signin(user.login, user.password).sid

      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("uploadMap", sid: user.sid).result).to.equal "paramMissed"

      it 'should allow users to create maps', ->
        expect(uploadMap(user.sid, "testUploadedMap", 16, ["."]).result).to.equal "ok"

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(uploadMap(user.sid + "@#&*^@#$!}}", "testBadSid", 10, ["."]).result).to.equal "badSid"

      it 'should respond with "badName" if map name was empty', ->
        expect(uploadMap(user.sid, "", 10, ["."]).result).to.equal "badName"

      it 'should respond with "badMaxPlayers" if maxPlayers field was empty', ->
        expect(uploadMap(user.sid, "badMaxPlayersTest", "", ["."]).result).to.equal "badMaxPlayers"

      it 'should respond with "badMap" if row lengths are not equal', ->
        expect(uploadMap(user.sid, "DiffLengthsTest", 16, ["...", "..", "..."]).result).to.equal "badMap"


    describe 'getMaps action', ->
      user =
        login: "mapGetterLogin"
        password: "mapGetterPass"
      map =
        name: "gettingMapsTest"
        maxPlayers: 4
        map: ["...", "...", "..."]

      beforeEach ->
        signup user.login, user.password
        user.sid = signin(user.login, user.password).sid
        uploadMap user.sid, map.name, map.maxPlayers, map.map



      it 'should allow users to get map list', ->
        getMapsRes = getMaps(user.sid)
        expect(getMapsRes.result).to.equal "ok"
        expect(getMapsRes.maps).to.not.be.undefined
        i = 0

        while i < getMapsRes.maps.length
          if getMapsRes.maps[i].name is map.name
            curMap = getMapsRes.maps[i]
            expect(curMap.map).to.eql map.map
            expect(curMap.maxPlayers).to.equal map.maxPlayers
          i++
      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("getMaps", {}).result).to.equal "paramMissed"

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(getMaps(user.sid + "$#%").result).to.equal "badSid"



  describe 'Game controlling', ->
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

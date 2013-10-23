describe 'Protocol supporting server', ->
  startRes = startTesting()
  if not startRes? or startRes.result isnt "ok"
    console.log "Testing could not be started"
    document.write "Testing could not be started"
    return

  it 'should respond with "badJSON" if it got string instead of params object', ->
    expect(getResponse("signup", "suddenly string").result).toBe "badJSON"

  it 'should respond with "badJSON" if it got array instead of params object', ->
    expect(getResponse("signup", [1, 2, 3]).result).toBe "badJSON"

  it 'should respond with "unknownAction" if it could not recognize action', ->
    expect(getResponse("asdkhasdasd", {}).result).toBe "unknownAction"

  it 'should respond with "unknownAction" if the action field was empty', ->
    expect(getResponse("", {}).result).toBe "unknownAction"

  describe 'signup action', ->
    it 'should respond with "paramMissed" if it did not receive all required params', ->
      expect(getResponse("signup", login: "some_login").result).toBe "paramMissed"
      expect(getResponse("signup", password: "some_password").result).toBe "paramMissed"

    it 'should require login and password', ->
      expect(signup("signup_test_login", "signup_test_password").result).toBe "ok"

    it 'should respond with "userExists" if this user already existed', ->
      expect(signup("existing_user", "existing_password").result).toBe "ok"
      expect(signup("existing_user", "existing_password").result).toBe "userExists"
      expect(signup("existing_user", "sdkfjhsdfkjhsdf").result).toBe "userExists"

    it 'should respond with "badLogin" if login was shorter than 4 symbols', ->
      expect(signup("1", "short_test_password").result).toBe "badLogin"

    it 'should respond with "badLogin" if login was longer than 40 symbols', ->
      expect(signup("abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz", "long_test_password").result).toBe "badLogin"

    it 'should respond with "badPassword" if password was shorter than 4 symbols', ->
      expect(signup("short_pass_login", "1").result).toBe "badPassword"

    it 'should respond with "badLogin" or "badPassword" if login and password were incorrect', ->
      expect(signup("sh", "sh").result).toMatch /badPassword|badLogin/


  describe 'signin action', ->
    it 'should respond with "paramMissed" if it did not receive all required params', ->
      expect(getResponse("signin", login: "some_login").result).toBe "paramMissed"
      expect(getResponse("signin", param: "some_password").result).toBe "paramMissed"

    it 'should respond with sid after the correct signin request', ->
      userLogin = "signin_test_login"
      userPass = "signin_test_pass"
      expect(signup(userLogin, userPass).result).toBe "ok"
      got = signin(userLogin, userPass)
      expect(got.result).toBe "ok"
      expect(got.sid).toBeDefined()
      expect(got.sid).toMatch /^[a-zA-z0-9]+$/

    it 'should respond with "incorrect" if user with requested login did not exist', ->
      userLogin = "signin_incorrect_l_test_login"
      userPass = "signin_incorrect_l_test_pass"
      expect(signup(userLogin, userPass).result).toBe "ok"
      expect(signin(userLogin + "no", userPass).result).toBe "incorrect"
      expect(signin(userLogin, userPass + "no").result).toBe "incorrect"

    it 'should respond with "incorrect" if login and password did not match', ->
      userLogin = "signin_incorrect_p_test_login"
      userPass = "signin_incorrect_p_test_pass"
      expect(signup(userLogin, userPass).result).toBe "ok"
      expect(signin(userLogin, userPass + "no").result).toBe "incorrect"

    it 'should respond with "incorrect" if login was empty', ->
      expect(signin("", "123").result).toBe "incorrect"


  describe 'signout action', ->
    it 'should respond with "paramMissed" if it did not receive all required params', ->
      expect(getResponse("signout", {}).result).toBe "paramMissed"

    it 'should allow user to sign out using the sid', ->
      userLogin = "signout_test_login"
      userPassword = "singout_test_pass"
      expect(signup(userLogin, userPassword).result).toBe "ok"
      signinResponse = signin(userLogin, userPassword)
      expect(signinResponse.result).toBe "ok"
      expect(signout(signinResponse.sid).result).toBe "ok"

    it 'should respond with "badSid" if sid was empty', ->
      expect(signout("").result).toBe "badSid"

    it 'should respond with "badSid" if sid could not be found', ->
      expect(signout("sidNotFound123").result).toBe "badSid"

    it 'should respond with "badSid" if user was not signed in', ->
      userLogin = "singed_out_user"
      userPassword = "signed_out_pass"
      signup userLogin, userPassword
      sid = signin(userLogin, userPassword).sid
      expect(signout(sid).result).toBe "ok"
      expect(signout(sid).result).toBe "badSid"


  describe 'Messages', ->
    firstUser =
      login: "mess_test_login1"
      password: "mess_test_pass1"

    secondUser =
      login: "mess_test_login2"
      password: "mess_test_pass2"

    signup firstUser.login, firstUser.password
    signup secondUser.login, secondUser.password
    beforeEach ->
      firstUser.sid = signin(firstUser.login, firstUser.password).sid
      secondUser.sid = signin(secondUser.login, secondUser.password).sid

    describe 'sendMessage action', ->
      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("sendMessage", {sid: firstUser.sid, game: ""}).result).toBe "paramMissed"
        expect(getResponse("sendMessage", {sid: firstUser.sid, text: "some text"}).result).toBe "paramMissed"
        expect(getResponse("sendMessage", {game: "", text: "some text"}).result).toBe "paramMissed"

      it 'should allow user to send text to chat using sid', ->
        expect(sendMessage(firstUser.sid, "", "Hello").result).toBe "ok"

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(sendMessage("^&%DF&TSDFH", "", "Hello").result).toBe "badSid"


    describe 'getMessages action', ->
      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("getMessages", sid: firstUser.sid).result).toBe "paramMissed"

      it 'should allow user to get messages using sid', ->
        firstText = "Hello, second"
        secondText = "Hi, first"
        expect(sendMessage(firstUser.sid, "", firstText).result).toBe "ok"
        expect(sendMessage(secondUser.sid, "", secondText).result).toBe "ok"
        getMessagesResponse = getMessages(firstUser.sid, "", 0)
        expect(getMessagesResponse.result).toBe "ok"
        firstMessage = getMessagesResponse.messages[getMessagesResponse.messages.length - 2]
        secondMessage = getMessagesResponse.messages[getMessagesResponse.messages.length - 1]
        expect(secondMessage.time).toBeGreaterThan firstMessage.time
        firstAuthor = (if firstMessage.login is firstUser.login then firstUser else secondUser)
        secondAuthor = (if secondMessage.login is secondUser.login then secondUser else firstUser)
        expect(firstMessage.login).toBe firstAuthor.login
        expect(firstMessage.text).toBe firstText
        expect(secondMessage.login).toBe secondAuthor.login
        expect(secondMessage.text).toBe secondText

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(getMessages(firstUser.sid + "#W*&^W#$", "", 0).result).toBe "badSid"

      it 'should respond with "badGame" if game with that id was not found', ->
        expect(getMessages(firstUser.sid, "#$(*&", 0).result).toBe "badGame"

      it 'should respond with "badSince" if the "since" timestamp was not cool', ->
        expect(getMessages(firstUser.sid, "", "suddenly not time").result).toBe "badSince"



  describe 'Map controlling', ->
    describe 'uploadMap action', ->
      user =
        login: "mapUploaderLogin"
        password: "mapUploaderPass"

      signup user.login, user.password
      user.sid = signin(user.login, user.password).sid

      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("uploadMap", sid: user.sid).result).toBe "paramMissed"

      it 'should allow users to create maps', ->
        expect(uploadMap(user.sid, "testUploadedMap", 16, ["."]).result).toBe "ok"

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(uploadMap(user.sid + "@#&*^@#$!}}", "testBadSid", 10, ["."]).result).toBe "badSid"

      it 'should respond with "badName" if map name was empty', ->
        expect(uploadMap(user.sid, "", 10, ["."]).result).toBe "badName"

      it 'should respond with "badMaxPlayers" if maxPlayers field was empty', ->
        expect(uploadMap(user.sid, "badMaxPlayersTest", "", ["."]).result).toBe "badMaxPlayers"

      it 'should respond with "badMap" if row lengths are not equal', ->
        expect(uploadMap(user.sid, "DiffLengthsTest", 16, ["...", "..", "..."]).result).toBe "badMap"


    describe 'getMaps action', ->
      user =
        login: "mapGetterLogin"
        password: "mapGetterPass"

      signup user.login, user.password
      user.sid = signin(user.login, user.password).sid
      map =
        name: "gettingMapsTest"
        maxPlayers: 4
        map: ["...", "...", "..."]

      uploadMap user.sid, map.name, map.maxPlayers, map.map
      it 'should allow users to get map list', ->
        getMapsRes = getMaps(user.sid)
        expect(getMapsRes.result).toBe "ok"
        expect(getMapsRes.maps).toBeDefined()
        i = 0

        while i < getMapsRes.maps.length
          if getMapsRes.maps[i].name is map.name
            curMap = getMapsRes.maps[i]
            console.log curMap
            expect(curMap.map).toEqual map.map
            expect(curMap.maxPlayers).toBe map.maxPlayers
          i++
      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("getMaps", {}).result).toBe "paramMissed"

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(getMaps(user.sid + "$#%").result).toBe "badSid"



  describe 'Game controlling', ->
    hostUser =
      login: "host_user"
      password: "host_pass"

    joiningUser =
      login: "joiner_login"
      password: "joiner_pass"

    signup hostUser.login, hostUser.password
    signup joiningUser.login, joiningUser.password
    hostUser.sid = signin(hostUser.login, hostUser.password).sid
    joiningUser.sid = signin(joiningUser.login, joiningUser.password).sid
    uploadMap hostUser.sid, "testMap", 4, ["..", ".."]
    uploadMap hostUser.sid, "testMap2", 4, ["."]
    maps = getMaps(hostUser.sid).maps
    afterEach ->
      leaveGame hostUser.sid
      leaveGame joiningUser.sid

    map = maps[0]
    map2 = maps[1]
    describe 'createGame action', ->
      it 'should respond with "paramMissed" if it did not receive all required params', ->
        expect(getResponse("createGame", sid: hostUser.sid).result).toBe "paramMissed"

      it 'should allow users to create games', ->
        expect(createGame(hostUser.sid, map.name + "Game", map.id, map.maxPlayers).result).toBe "ok"

      it 'should respond with "gameExists" if game with requested name already exists', ->
        gameName = "gameNumber1"
        expect(createGame(hostUser.sid, gameName, map.id, map.maxPlayers).result).toBe "ok"
        expect(createGame(joiningUser.sid, gameName, map2.id, map2.maxPlayers).result).toBe "gameExists"

      it 'should respond with "badName" if game name was empty', ->
        expect(createGame(hostUser.sid, "", map.id, map.maxPlayers).result).toBe "badName"

      it 'should respond with "badMap" if map with that id was not found', ->
        expect(createGame(hostUser.sid, "badMapGame", map.id + "@#$@#$", map.maxPlayers).result).toBe "badMap"

      it 'should respond with "badMap" if requested map id was empty', ->
        expect(createGame(hostUser.sid, "emptyMapNameGame", "", map.maxPlayers).result).toBe "badMap"

      it 'should respond with "badMaxPlayers" if maxPlayers field was empty', ->
        expect(createGame(hostUser.sid, "badMaxPlayersGame", map.id, "").result).toBe "badMaxPlayers"

      it 'should respond with "badMaxPlayers" if maxPlayers field was not like correct number', ->
        expect(createGame(hostUser.sid, "badMaxPlayersNaNGame", map.id, "suddenly!").result).toBe "badMaxPlayers"

      it 'should respond with "alreadyInGame" if host user was trying to create two games simultaneously', ->
        expect(createGame(hostUser.sid, "AlreadyInGameGame1", map.id, map.maxPlayers).result).toBe "ok"
        expect(createGame(hostUser.sid, "AlreadyInGameGame2", map2.id, map.maxPlayers).result).toBe "alreadyInGame"


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
        expect(getResponse("getGames", {}).result).toBe "paramMissed"

      it 'should allow users to get game list', ->
        getGamesResponse = getGames(joiningUser.sid)
        expect(getGamesResponse.result).toBe "ok"
        expect(getGamesResponse.games).toBeDefined()
        i = 0

        while i < getGamesResponse.games.length
          if getGamesResponse.games[i].name is game.name
            cur = getGamesResponse.games[i]
            expect(cur.map).toBe game.map
            expect(cur.maxPlayers).toBe game.maxPlayers
            expect(cur.players.length).toBe 1
            expect(cur.players[0]).toBe hostUser.login

          i++

      it "should respond with object containing players array sorted by join time", ->
        joinGame joiningUser, game.id
        getGamesResponse = getGames joiningUser.sid
        expect(getGamesResponse.result).toBe "ok"
        expect(getGamesResponse.games).toBeDefined()
        i = 0
        while i < getGamesResponse.games.length
          if getGamesResponse.games[i].name is game.name
            cur = getGamesResponse.games[i]
            expect(cur.map).toBe game.map
            expect(cur.maxPlayers).toBe game.maxPlayers
            expect(cur.players.length).toBe 2
            expect(cur.players[0]).toBe hostUser.login
            expect(cur.players[1]).toBe joiningUser.login

          i++

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(getGames(joiningUser.sid + "#(&@(&@$").result).toBe "badSid"


    describe 'joinGame action', ->
      gameCreator =
        login: "gameCreator"
        password: "hosterPass"

      signup gameCreator.login, gameCreator.password
      gameCreator.sid = signin(gameCreator.login, gameCreator.password).sid
      game =
        name: "joinGameTest"
        map: map.id
        maxPlayers: 2

      createGame gameCreator.sid, game.name, game.map, game.maxPlayers
      games = getGames(joiningUser.sid).games
      i = 0

      while i < games.length
        if games[i].name is game.name
          game.id = games[i].id
          break
        i++
      it 'should allow users to join game using the sid and game id', ->
        expect(joinGame(joiningUser.sid, game.id).result).toBe "ok"

      it 'should respond with "badSid" if user with that sid was not found', ->
        expect(joinGame(joiningUser.sid + "#@(*#q", game.id).result).toBe "badSid"

      it 'should respond with "badGame" if game id was like some string', ->
        expect(joinGame(joiningUser.sid, game.id + "#@(&").result).toBe "badGame"

      it 'should respond with "badGame" if game id was empty', ->
        expect(joinGame(joiningUser.sid, "").result).toBe "badGame"

      it 'should respond with "badGame" if game id was empty', ->
        expect(joinGame(joiningUser.sid, "").result).toBe "badGame"

      it 'should respond with "gameFull" if max players amount was reached', ->
        expect(joinGame(joiningUser.sid, game.id).result).toBe "ok"
        oddManOut =
          login: "oddLogin"
          password: "oddPassword"

        signup oddManOut.login, oddManOut.password
        oddManOut.sid = signin(oddManOut.login, oddManOut.password).sid
        expect(joinGame(oddManOut.sid, game.id).result).toBe "gameFull"


    describe 'leaveGame action', ->
      game =
        name: "leaveGameTest"
        map: map.id
        maxPlayers: 3

      beforeEach ->
        createGame hostUser.sid, game.name, game.map, game.maxPlayers

      it 'should respond with "paramMissed if it did not receive all required params ', ->
        expect(getResponse("leaveGame", {}).result).toBe "paramMissed"

      it 'should allow host users to leave created games', ->
        expect(leaveGame(hostUser.sid).result).toBe "ok"

      it 'should respond with "notInGame" if user trying to leave game was not in any', ->
        expect(leaveGame(joiningUser.sid).result).toBe "notInGame"

      it 'should respong with "badSid" if user with that sid was not found', ->
        expect(leaveGame(joiningUser.sid + "@#$@#$").result).toBe "badSid"





class Psg.GameplayTester

  constructor: ->
    @precision = Math.round Math.abs Math.log(config.game.defaultConsts.accuracy) / Math.LN10
    @done = null
    @users = []

  setup: (conn) ->
    @conn = conn
    @commands = []
    @curTick = 0

  checkPlayer: (got, expected = @expectedPlayer) ->
    console.log 'checking player'
    for prop of expected
      console.log "#{prop}:"
      console.log '  got: ', got[prop]
      console.log '  expected: ', expected[prop]
      expect(got[prop]).to.almost.eql expected[prop], @precision

  addCommand: (command, {begin, end} = {}) ->
    begin ?= if @commands.length > 0 then _.last(@commands).end + 1 else 0
    end ?= begin
    @commands.push
      exec: command
      begin: begin + @curTick
      end: end + @curTick

  addUser: (user, gameid) ->
    user.gameid = gameid
    @users.push user

  joinUser: (user) ->
    deferred = $.Deferred()
    user.joinGame(user.gameid).then ->
      user.gc = new Psg.GameplayConnection(user.sid, deferred)

    return deferred

  joinGame: (user_idx, next_idx) ->
    user = @users[user_idx]
    res = null
    if next_idx < @users.length
      res = @joinGame(next_idx, next_idx + 1)

    if res
      deferred = $.Deferred()
      res.then =>
        @joinUser(user).then =>
          deferred.resolve()

      return deferred
    else
      return @joinUser(user)


  leaveGame: (user_idx, next_idx) ->
    user = @users[user_idx]


    res = null
    if next_idx? and next_idx < @users.length
      res = @leaveGame(next_idx, next_idx + 1)

    deferred = $.Deferred()
    if res
      res.then =>
        user.leaveGame().then =>
          user.gc.close()
          deferred.resolve()

      return deferred
    else
      return user.leaveGame().then =>
        user.gc.close()

  loginUser: (user) ->
    deferred = $.Deferred()
    user.signup().then =>
      user.signin().then =>
        deferred.resolve()

    return deferred

  loginUsers: (user_idx, next_idx) ->
    user = @users[user_idx]

    res = null
    if next_idx < @users.length
      res = @loginUsers(next_idx, next_idx + 1)

    if res
      deferred = $.Deferred()
      res.then =>
        @loginUser(user).then =>
          deferred.resolve()

      return deferred
    else
      return @loginUser(user)


  defineTest: (callback) ->

    runTest = =>
      console.log "TEEEST"
      @expectedPlayer = null
      @execDefinition = callback
      @execDefinition()
      @conn.onmessage = (data) =>
        console.log 'message got'
        @data = data
        if @expectedPlayer?
          for p, i in @data.players
            console.log "players[#{i}]:"
            for prop of @expectedPlayer
              console.log "  #{prop}: ", p[prop]
        for c in @commands
          if c.begin <= @curTick <= c.end
            @exec = c.exec
            @exec()
        @curTick++
      if @conn.lostData?
        @conn.onmessage @conn.lostData

    if @users.length > 0
      @loginUsers(0, 1).then =>
        @joinGame(0, 1).then =>
          runTest()
    else
      runTest()







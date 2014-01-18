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
      res.then =>
        return @joinUser(user)
    else
      @joinUser(user)


  leaveGame: (user_idx, next_idx) ->
    user = @users[user_idx]


    res = null
    if next_idx? and next_idx < @users.length
      res = @leaveGame(next_idx, next_idx + 1)

    if res
      res.then =>
        return user.leaveGame().then =>
          user.gc.close()
    else
      user.leaveGame().then =>
        user.gc.close()

  loginUser: (user) ->
    done = user.signup().then =>
      return user.signin()

  loginUsers: (user_idx, next_idx) ->
    user = @users[user_idx]

    res = null
    if next_idx < @users.length
      res = @loginUsers(next_idx, next_idx + 1)

    if res
      res.then =>
        return @loginUser(user)
    else
      @loginUser(user)


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







class Psg.GameplayTester

  constructor: ->
    @precision = Math.round Math.abs Math.log(config.game.defaultConsts.accuracy) / Math.LN10

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

  defineTest: (callback) ->
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


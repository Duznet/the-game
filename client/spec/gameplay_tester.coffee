class Psg.GameplayTester

  setup: (conn) ->
    @conn = conn
    @commands = []
    @curTick = 0

  addCommand: (command, {begin, end} = {}) ->
    begin ?= if @commands.length > 0 then _.last(@commands).end + 1 else 0
    end ?= begin
    @commands.push
      exec: command
      begin: begin + @curTick
      end: end + @curTick

  defineTest: (callback) ->
    @execDefinition = callback
    @execDefinition()
    @conn.onmessage = (data) =>
      @data = data
      for c in @commands
        if c.begin <= @curTick <= c.end
          @exec = c.exec
          @exec()
      @curTick++
    if @conn.lostData?
      @conn.onmessage @conn.lostData


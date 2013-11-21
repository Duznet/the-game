class window.Drawer

  constructor: (@canvas) ->
    @dfd = new $.Deferred
    @conn = new Psg.GameConnection config.gameUrl
    @gen = new Psg.Generator 'demo'

    @map =
      name: @gen.getStr()
      maxPlayers: 4
      map: ["#..........................#",
            "#......1...$...2...........#",
            "#.....###########..........#",
            "#..........................#",
            "#...2..............1.......#",
            "######################.....#",
            "#..........................#",
            "############################",
            ]

    @user = @gen.getUser()
    console.log "generated user: ", @user
    @conn.startTesting('async')
    .then =>
    @user.signup()
    .then (data) =>
      @user.signin()
    .then =>
      @user.uploadMap(@map.name, @map.maxPlayers, @map.map)
    .then =>
      @user.getMaps()
    .then (data) =>
      maps = data.maps.filter (m) => m.name is @map.name
      @map = maps[0]
      console.log "map is ", @map
      @user.createGame(@gen.getStr(), @map.maxPlayers, @map.id)
    .then (data) =>
      console.log "game created"
      if data.result isnt "ok"
        throw new Error "Could not start the game"
      @dfd.resolve()

  drawMap: ->
    console.log "drawing map"
    @scale = @canvas.width / @map.map[0].length
    paper.install window
    paper.setup @canvas.id
    console.log "map is ", @map
    console.log "scale is ", @scale
    for row, i in @map.map
      for col, j in @map.map[i]
        rect = new Shape.Rectangle new Point(j * @scale, i * @scale), new Size(@scale, @scale)
        if col is '#'
          rect.strokeColor = 'black'
        else if '1' <= col.toString() <= '9'
          rect.fillColor = 'yellow'
        else if col is '$'
          rect.fillColor = 'blue'



  startGame: ->
    @drawMap()
    player = new Shape.Rectangle new Point(15, 15), new Size(@scale, @scale)
    player.strokeColor = 'black'
    player.fillColor = 'red'
    @playerPosition = new Point(0, 0)
    @v = new Point(0, 0)
    @gc = new Psg.GameplayConnection config.gameplayUrl
    @tick = 0
    @gc.ws.onopen = =>
      @gc.move @user.sid, @tick, 0, 0
    @gc.ws.onmessage = (event) =>
      data = JSON.parse event.data
      @tick = data.tick
      # @v = x: data.players[0].x * @scale, y: data.players[0].y * @scale
      @playerPosition = new Point(@scale * data.players[0].x, @scale * data.players[0].y)

    onKeyDown = (event) =>
      if event.key is "w"
        @gc.move @user.sid, @tick, 0, -1
      if event.key is "a"
        @gc.move @user.sid, @tick, -1, 0
      if event.key is "s"
        @gc.move @user.sid, @tick, 0, 1
      if event.key is "d"
        @gc.move @user.sid, @tick, 1, 0

    onFrame = =>
      if @playerPosition.x isnt player.position.x or @playerPosition.y isnt player.position.y
        player.position = @playerPosition

    tool.attach 'keydown', onKeyDown
    view.attach 'frame', onFrame
    console.log "game started"






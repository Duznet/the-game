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
    teorFps = Math.round 1000 / config.defaultGameConsts.tickSize
    fps = 0
    lastFps = 0
    setInterval ->
      lastFps = Math.min Math.round(fps * 1000 / config.fpsCalcInterval), teorFps
      console.log 'fps: ', lastFps
      fps = 0
    , config.fpsCalcInterval
    @playerVelocity = new Point(0, 0)
    @gc.onopen = =>
      @gc.move @user.sid, @tick, 0, 0
    @gc.onmessage = (data) =>
      if data.tick < @tick then return
      fps++
      @tick = data.tick
      # @v = x: data.players[0].x * @scale, y: data.players[0].y * @scale
      @playerPosition = new Point(@scale * data.players[0].x, @scale * data.players[0].y)
      @playerVelocity = new Point(@scale * data.players[0].vx, @scale * data.players[0].vy)

    onKeyDown = (event) =>
      dx = 0
      dy = 0
      if /^[wц]$|up|space/.test event.key
        dy--
      if /^[aф]$/.test event.key
        dx--
      if /^[sы]$/.test event.key
        dy++
      if /^[dв]$/.test event.key
        dx++
      @gc.move @user.sid, @tick, dx, dy

    onFrame = (event) =>
      if @playerPosition.x isnt player.position.x or @playerPosition.y isnt player.position.y
        player.position = @playerPosition
      else
        t = 1000 / config.defaultGameConsts.tickSize * event.delta
        if config.interpolate
          player.position.x += t * @playerVelocity.x * (lastFps / teorFps)
          player.position.y += t * @playerVelocity.y * (lastFps / teorFps)
          @playerPosition = player.position

    tool.attach 'keydown', onKeyDown
    view.attach 'frame', onFrame
    console.log "game started"






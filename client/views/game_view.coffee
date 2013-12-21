class Psg.GameView extends Backbone.View

  template: _.template $('#game-template').html()

  initialize: ->
    @render()
    @listenTo @model, 'gameReady', @startGame

  render: ->
    @$el.appendTo('#content')
    @$el.html @template()

  drawMap: ->
    mapData = @model.map.map
    console.log "drawing map"
    $canvas = $('#game-canvas')
    console.log 'canvas: ', $canvas
    @scale = $canvas.width() / mapData[0].length
    paper.install window
    paper.setup 'game-canvas'
    console.log "scale is ", @scale
    console.log 'mapData: ', mapData
    for row, i in mapData
      for col, j in row
        console.log 'col: ', col
        rect = new Shape.Rectangle new Point(j * @scale, i * @scale), new Size(@scale, @scale)
        if col is '#'
          rect.strokeColor = 'black'
          console.log 'rect: ', rect
        else if '1' <= col.toString() <= '9'
          rect.fillColor = 'yellow'
        else if col is '$'
          rect.fillColor = 'blue'
    console.log 'map drawn'

  startGame: ->
    @drawMap()
    @pViews = []
    # player = new Shape.Rectangle new Point(15, 15), new Size(@scale, @scale)
    # player.strokeColor = 'black'
    # player.fillColor = 'red'
    # @playerPosition = new Point(0, 0)
    # @v = new Point(0, 0)
    @gc = new Psg.GameplayConnection config.gameplayUrl
    sid = @model.get('user').get('sid')
    @tick = 0
    teorFps = Math.round 1000 / config.defaultGameConsts.tickSize
    fps = 0
    lastFps = 0
    dx = 0
    dy = 0
    setInterval ->
      lastFps = Math.min Math.round(fps * 1000 / config.fpsCalcInterval), teorFps
      # console.log 'fps: ', lastFps
      fps = 0
    , config.fpsCalcInterval
    setInterval =>
      if dx isnt 0 or dy isnt 0 then @gc.move sid, @tick, dx, dy
    , config.defaultGameConsts.tickSize / 2
    # @playerVelocity = new Point(0, 0)
    @gc.onopen = =>
      @gc.move sid, @tick, 0, 0
    @gc.onmessage = (data) =>
      if data.tick < @tick then return
      fps++
      @tick = data.tick
      # @v = x: data.players[0].x * @scale, y: data.players[0].y * @scale
      players = data.players
      for p, i in players
        if i is @pViews.length
          @pViews.push new Shape.Rectangle new Point(0, 0), new Size(@scale, @scale)
          @pViews[i].strokeColor = 'black'
          @pViews[i].fillColor = 'red'
        @pViews[i].position.x = @scale * p.x
        @pViews[i].position.y = @scale * p.y

      # @playerPosition = new Point(@scale * data.players[0].x, @scale * data.players[0].y)
      # @playerVelocity = new Point(@scale * data.players[0].vx, @scale * data.players[0].vy)

    onKeyDown = (event) =>
      if /^[wц]$|up|space/.test event.key
        dy--
      if /^[aф]$|left/.test event.key
        dx--
      if /^[sы]$|down/.test event.key
        dy++
      if /^[dв]$|right/.test event.key
        dx++
      dx = if dx > 0 then 1 else if dx < 0 then -1 else 0
      dy = if dy > 0 then 1 else if dy < 0 then -1 else 0

    onKeyUp = (event) =>
      if /^[wц]$|up|space/.test event.key
        dy = 0
      if /^[aф]$|left/.test event.key
        dx = 0
      if /^[sы]$|down/.test event.key
        dy = 0
      if /^[dв]$|right/.test event.key
        dx = 0

    onFrame = (event) =>
      for p in @pViews
        p.position = p.position

      # if @playerPosition.x isnt player.position.x or @playerPosition.y isnt player.position.y
      #   player.position = @playerPosition
      # else
      #   t = 1000 / config.defaultGameConsts.tickSize * event.delta
      #   if config.interpolate
      #     player.position.x += t * @playerVelocity.x * (lastFps / teorFps)
      #     player.position.y += t * @playerVelocity.y * (lastFps / teorFps)
      #     @playerPosition = player.position

    tool.attach 'keydown', onKeyDown
    tool.attach 'keyup', onKeyUp
    view.attach 'frame', onFrame
    console.log "game started"


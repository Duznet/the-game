class Psg.GameView extends Backbone.View

  template: _.template $('#game-template').html()

  initialize: ->
    @render()
    paper.install window
    paper.setup 'game-canvas'

  render: ->
    @$el.appendTo('#content')
    @$el.html @template()

  drawMap: ->
    console.log "drawing map"
    mapData = @model.game.map.map
    $canvas = $('#game-canvas')
    @scale = $canvas.width() / mapData[0].length
    console.log "scale is ", @scale
    console.log 'mapData: ', mapData
    mapDrawer = new Psg.MapDrawer scale: @scale
    mapDrawer.draw(mapData)

  onmessage: (data) =>
    players = data.players
    for p, i in players
      if i is @pViews.length
        @pViews.push new Shape.Rectangle new Point(0, 0), new Size(@scale, @scale)
        @pViews[i].strokeColor = 'black'
        @pViews[i].fillColor = 'red'
        @pViews[i].onFrame = (event) -> @position = @position
      @pViews[i].position.x = @scale * p[0]
      @pViews[i].position.y = @scale * p[1]

  startGame: ->
    @drawMap()
    @pViews = []
    # teorFps = Math.round 1000 / config.defaultGameConsts.tickSize
    # fps = 0
    # lastFps = 0
    # setInterval ->
    #   lastFps = Math.min Math.round(fps * 1000 / config.fpsCalcInterval), teorFps
    #   console.log 'fps: ', lastFps
    #   fps = 0
    # , config.fpsCalcInterval
    @model.startGame(onmessage: @onmessage)

    onKeyDown = (event) =>
      if /^[wц]$|up|space/.test event.key
        @model.player.movement.dy--
      if /^[aф]$|left/.test event.key
        @model.player.movement.dx--
      if /^[sы]$|down/.test event.key
        @model.player.movement.dy++
      if /^[dв]$|right/.test event.key
        @model.player.movement.dx++
      dx = @model.player.movement.dx
      dy = @model.player.movement.dy
      dx = if dx > 0 then 1 else if dx < 0 then -1 else 0
      dy = if dy > 0 then 1 else if dy < 0 then -1 else 0

    onKeyUp = (event) =>
      if /^[wц]$|up|space/.test event.key
        @model.player.movement.dy = 0
      if /^[aф]$|left/.test event.key
        @model.player.movement.dx = 0
      if /^[sы]$|down/.test event.key
        @model.player.movement.dy = 0
      if /^[dв]$|right/.test event.key
        @model.player.movement.dx = 0

    tool.attach 'keydown', onKeyDown
    tool.attach 'keyup', onKeyUp
    console.log "game started"


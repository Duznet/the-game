class Psg.GameView extends Backbone.View

  template: _.template $('#game-template').html()

  initialize: ->
    @render()
    paper.install window
    paper.setup 'game-canvas'
    @projectiles = []

  render: ->
    @$el.appendTo('#content')
    @$el.html @template()

  drawMap: ->
    console.log "drawing map"
    mapData = @model.game.map.map
    @scale = config.game.scale
    console.log "scale is ", @scale
    console.log 'mapData: ', mapData
    mapDrawer = new Psg.MapDrawer
    mapDrawer.draw(mapData)
    @items = mapDrawer.items

  startGame: ->
    @drawMap()
    @pViews = []
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

    onMouseDown = (event) =>
      @model.player.fire =
        dx: event.point.x / @scale - @model.player.position.x
        dy: event.point.y / @scale - @model.player.position.y
    onMouseDrag = (event) =>
      @model.player.fire =
        dx: event.point.x / @scale - @model.player.position.x
        dy: event.point.y / @scale - @model.player.position.y
    onMouseUp = (event) =>
      @model.player.fire = dx: 0, dy: 0

    onFrame = (event) =>
      players = @model.players
      for login, p of @model.players
        if not @pViews[login]
          @pViews[login] = new Psg.PlayerView
        pView = @pViews[login]
        pView.moveTo p.position
        if login is @model.get('user').get('login')
          @playerView = pView

      if not @playerView then return
      view.scrollBy [@playerView.position.x - view.center.x, @playerView.position.y - view.center.y]

    tool.attach 'keydown', onKeyDown
    tool.attach 'keyup', onKeyUp
    tool.attach 'mousedown', onMouseDown
    tool.attach 'mousedrag', onMouseDrag
    tool.attach 'mouseup', onMouseUp
    view.attach 'frame', onFrame
    console.log "game started"


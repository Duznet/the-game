class Psg.GameView extends Backbone.View

  template: _.template $('#game-template').html()

  initialize: ->
    @render()
    paper.install window
    paper.setup 'game-canvas'
    @projectiles = []
    @pressedKeys = left: 0, up: 0, right: 0, down: 0

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

  codeIsDirected: (code, direction) ->
    switch direction
      when 'left' then code is 37 or code is 65
      when 'up' then code is 38 or code is 87 or code is 32
      when 'right' then code is 39 or code is 68
      when 'down' then code is 40 or code is 83

  updateMovement: ->
    @model.player.movement.dx = @pressedKeys.right - @pressedKeys.left
    @model.player.movement.dy = @pressedKeys.down - @pressedKeys.up

  updateKeys: (code, eventType) ->
    for p of @pressedKeys
      if @codeIsDirected code, p
        @pressedKeys[p] = eventType is 'keydown'
    @updateMovement()

  onKeyDown: (event) =>
    @updateKeys event.keyCode, 'keydown'

  onKeyUp: (event) =>
    @updateKeys event.keyCode, 'keyup'

  startGame: ->
    @drawMap()
    @pViews = []
    @model.startGame(onmessage: @onmessage)
    $canvas = $('#game-canvas')
    $canvas.attr 'tabindex', '0'
    $canvas.focus()
    $canvas.keydown @onKeyDown
    $canvas.keyup @onKeyUp
    @login = @model.get('user').get('login')

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
        if login is @login
          @playerPosition = pView.position

      if not @playerPosition then return
      view.scrollBy [@pViews[@login].position.x - view.center.x, @pViews[@login].position.y - view.center.y]

    tool.attach 'mousedown', onMouseDown
    tool.attach 'mousedrag', onMouseDrag
    tool.attach 'mouseup', onMouseUp
    view.attach 'frame', onFrame
    console.log "game started"


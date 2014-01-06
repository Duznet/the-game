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
    @projectiles = []
    @model.startGame(onmessage: @onmessage)
    if config.game.showSight
      @sight = new Psg.SightView
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
    onMouseMove = (event) =>
      if config.game.showSight
        @sight.moveTo event.point
        @sight.saveOffset view.center
    onMouseDrag = (event) =>
      onMouseMove(event)
      @model.player.fire =
        dx: event.point.x / @scale - @model.player.position.x
        dy: event.point.y / @scale - @model.player.position.y
    onMouseUp = (event) =>
      @model.player.fire = dx: 0, dy: 0

    onFrame = (event) =>
      players = @model.players
      for login, p of @model.players
        if not @pViews[login]
          @pViews[login] = new Psg.PlayerView p
        pView = @pViews[login]
        pView.moveTo
          x: p.position.x * @scale
          y: p.position.y * @scale
        if @model.players[login].velocity.x * pView.sign < 0
          pView.flip()
        if login is @login
          @playerPosition = pView.getPosition()
        if login is @login or config.showHealth
          pView.label.content = "#{login} (#{p.health})"

      if not @playerPosition then return
      view.scrollBy [@playerPosition.x - view.center.x, @playerPosition.y - view.center.y]
      if config.game.showSight
        @sight.moveTo
          x: view.center.x + @sight.offset.x
          y: view.center.y + @sight.offset.y

      if @model.projectilesInvalidated
        @model.projectilesInvalidated = false
        for p in @projectiles
          p.shape.remove()
        @projectiles = []
        for p in @model.projectiles
          if p.velocity.x is 0 and p.velocity.y is 0 then continue
          v = new Psg.ProjectileView p
          @projectiles.push v

      for respawn, index in @model.items
        @items[index].respawn = respawn


    tool.attach 'mousedown', onMouseDown
    tool.attach 'mousedrag', onMouseDrag
    tool.attach 'mousemove', onMouseMove
    tool.attach 'mouseup', onMouseUp

    view.attach 'frame', onFrame
    console.log "game started"


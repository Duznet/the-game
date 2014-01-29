class Psg.GameView extends Backbone.View

  template: _.template $('#game-template').html()

  initialize: ->
    @render()
    paper.install window
    paper.setup 'game-canvas'
    @projectiles = []
    @animations = []
    @pressedKeys = left: 0, up: 0, right: 0, down: 0

  render: ->
    @$el.appendTo('#content')
    @$el.html @template()

  generateColor: ->
    c = new Color
    c.brightness = 0.5 + 0.2 * Math.random()
    c.saturation = 0.5
    c.hue = 100 * Math.round(20 * Math.random())
    if config.showPlayersColors
      console.log 'saturation: ', c.saturation
      console.log 'hue: ', c.hue
      console.log 'brightness: ', c.brightness
    c

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
    if event.keyCode is 69
      @stats.visible = true
    else
      @updateKeys event.keyCode, 'keydown'

  onKeyUp: (event) =>
    if event.keyCode is 69
      @stats.visible = false
    else
      @updateKeys event.keyCode, 'keyup'

  onMouseDown: (event) =>
    @model.player.fire =
      dx: event.point.x / @scale - @model.player.position.x
      dy: event.point.y / @scale - @model.player.position.y

  onMouseMove: (event) =>
    if config.game.showCrosshair
      @crosshair.moveTo event.point
      @crosshair.saveOffset view.center
    if @playerView?
      @playerView.onMouseMove(event)

  onMouseDrag: (event) =>
    @onMouseMove(event)
    @model.player.fire =
      dx: event.point.x / @scale - @model.player.position.x
      dy: event.point.y / @scale - @model.player.position.y

  onMouseUp: (event) =>
    @model.player.fire = dx: 0, dy: 0

  onFrame: (event) =>
    players = @model.players
    @statsText.content = ''
    for login, p of @model.players
      if not @pViews[login]
        p.color = @generateColor()
        @pViews[login] = new Psg.PlayerView p
      pView = @pViews[login]
      pView.moveTo
        x: p.position.x * @scale
        y: p.position.y * @scale
      pView.wound.visible = p.wounded
      pView.eye.fillColor = if p.wounded then 'red' else 'yellow'
      if p.weapon isnt pView.weapon
        pView.changeWeapon p.weapon
      if login is @login
        @playerView = pView
        @playerPosition = pView.getPosition()
      else
        if p.weaponAngle > -1
          pView.importWeaponAngle p.weaponAngle
      if login is @login or config.game.showHealth
        pView.label.content = "#{login} (#{p.health})"
      if p.respawn > 0 then pView.hide() else pView.show()
      @statsText.content += "#{p.login}:\tkills: #{p.statistics.kills}\tdeaths: #{p.statistics.deaths}\n"

    if not @playerPosition then return
    view.scrollBy [@playerPosition.x - view.center.x, @playerPosition.y - view.center.y]
    if config.game.showCrosshair
      @crosshair.moveTo
        x: view.center.x + @crosshair.offset.x
        y: view.center.y + @crosshair.offset.y
      @crosshair.shape.bringToFront()
    @stats.position = view.center

    if @model.playersLeft
      @model.playersLeft = false
      for login, pView of @pViews
        if not @model.players[login]?
          pView.remove()
          delete @pViews[login]

    if @model.projectilesInvalidated
      @model.projectilesInvalidated = false
      @projectiles = []
      for p in @model.projectiles
        v = new Psg.PROJECTILES[p.weapon] p
        @projectiles.push v
      for p in @animations
        p.remove() if p.finished
      @animations = @projectiles.concat(@animations.filter (p) -> not p.finished)
      for respawn, index in @model.items
        @items[index].respawn = respawn
    @stats.bringToFront()

  startGame: ->
    @drawMap()
    @pViews = []
    @projectiles = []
    @model.startGame(onmessage: @onmessage)
    if config.game.showCrosshair
      @crosshair = new Psg.CrosshairView
    $canvas = $('#game-canvas')
    $canvas.attr 'tabindex', '0'
    $canvas.focus()
    $canvas.keydown @onKeyDown
    $canvas.keyup @onKeyUp
    @login = @model.get('user').get('login')

    @statsRect = new Shape.Rectangle(view.bounds.scale(0.9))
    @statsRect.style =
      fillColor: 'black'
      strokeColor: 'black'
    @statsRect.fillColor = 'black'
    @statsRect
    @statsRect.fillColor.alpha = 0.8
    @statsText = new PointText([@statsRect.bounds.point.x + @scale, @statsRect.bounds.point.y + @scale])
    @statsText.fontSize = 24
    @statsText.fillColor = 'grey'
    @stats = new Group(@statsRect, @statsText)
    @stats.visible = false


    tool.attach 'mousedown', @onMouseDown
    tool.attach 'mousedrag', @onMouseDrag
    tool.attach 'mousemove', @onMouseMove
    tool.attach 'mouseup', @onMouseUp

    view.attach 'frame', @onFrame
    console.log "game started"


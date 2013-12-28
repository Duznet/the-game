class Psg.MapDrawer

  constructor: (attrs) ->
    attrs = attrs || {}
    @scale = attrs.scale || config.game.scale

  drawWall: (position) ->
    rect = new Shape.Rectangle position, new Size(@scale, @scale)
    rect.strokeColor = 'black'
    rect.fillColor = 'black'

  drawTeleport: (position) ->
    teleportSize = @scale / 2
    position.x += teleportSize / 2
    position.y += teleportSize / 2
    rect = new Shape.Rectangle position, new Size(teleportSize, teleportSize)
    rect.strokeColor = 'grey'
    rect.fillColor = 'yellow'
    rect.onFrame = ->
      @rotate(2)

  draw: (mapData) ->
    # paper must have been initialized
    length = mapData[0].length
    for j in [0...mapData[0].length]
      @drawWall new Point(j * @scale, -1 * @scale)
      @drawWall new Point(j * @scale, mapData.length * @scale)
    for i in [-1..mapData.length]
      @drawWall new Point(-1 * @scale, i * @scale)
      @drawWall new Point(mapData[0].length * @scale, i * @scale)

    for row, i in mapData
      for col, j in row
        if col is '.'
          continue
        if col is '#'
          @drawWall new Point(j * @scale, i * @scale)
        else if '1' <= col.toString() <= '9'
          @drawTeleport new Point(j * @scale, i * @scale)

class Psg.MapDrawer

  constructor: (attrs) ->
    attrs = attrs || {}
    @scale = attrs.scale || config.game.scale
    @items = []
    @walls =
      horizontal: []
      vertical: []

  wallIsDrawn: (i, j) ->
    for wallType of @walls
      for wall in @walls[wallType]
        switch wallType
          when 'horizontal'
            return true if wall.row is i and wall.begin <= j <= wall.end
          when 'vertical'
            return true if wall.col is j and wall.begin <= i <= wall.end
    return false

  drawScene: (attrs) ->
    scene = new Shape.Rectangle
      point: new Point(-0.5 * @scale, -0.5 * @scale)
      size: new Size((attrs.width + 1) * @scale, (attrs.height + 1) * @scale)
    scene.style =
      strokeColor: 'black'
      fillColor: '#ffe'
      strokeWidth: @scale

  drawWall: (wall) ->
    wallPoint = if wall.row?
      x: wall.begin
      y: wall.row
    else
      x: wall.col
      y: wall.begin
    wallSize = if wall.row?
      x: wall.end - wall.begin + 1
      y: 1
    else
      x: 1
      y: wall.end - wall.begin + 1
    shape = new Shape.Rectangle
      point:
        x: wallPoint.x * @scale
        y: wallPoint.y * @scale
      size:
        x: wallSize.x * @scale
        y: wallSize.y * @scale
    shape.style =
      strokeColor: 'black'
      fillColor: 'black'

  drawTeleport: (position) ->
    teleportSize = @scale / 2
    position.x += teleportSize / 2
    position.y += teleportSize / 2
    rect = new Shape.Rectangle position, new Size(teleportSize, teleportSize)
    rect.strokeColor = 'grey'
    rect.fillColor = 'yellow'
    rect.onFrame = ->
      @rotate(2)

  drawItem: (type, position) ->
    model = {}
    model.respawn = 0
    model.type = type
    model.position = x: position.x + 0.5, y: position.y + 0.5
    @items.push new Psg.MapItemView model

  draw: (mapData) ->
    # paper must have been initialized
    length = mapData[0].length
    @drawScene(width: length, height: mapData.length)


    for i in [0...mapData.length]
      for j in [0..mapData[0].length]
        if mapData[i][j] is '#' and not @wallIsDrawn(i, j)
          vertWall = col: j, begin: i
          horWall = row: i, begin: j
          k = j
          while k < mapData[0].length and mapData[i][k] is '#'
            horWall.end = k
            k++
          k = i
          while k < mapData.length and mapData[k][j] is '#'
            vertWall.end = k
            k++
          if horWall.end - horWall.begin >= vertWall.end - vertWall.begin
            @drawWall(horWall)
            @walls.horizontal.push horWall
          else
            @drawWall(vertWall)
            @walls.vertical.push vertWall
    console.log 'walls amount: ', @walls.horizontal.length + @walls.vertical.length


    for row, i in mapData
      for char, j in row
        if char is '.' or char is '#'
          continue
        if 'A' <= char <= 'Z' or 'a' <= char <= 'z'
          @drawItem char, new Point(j, i)
        else if '1' <= char.toString() <= '9'
          @drawTeleport new Point(j * @scale, i * @scale)

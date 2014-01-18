class Psg.WeaponView extends Psg.ObjectView

  constructor: (model) ->


class Psg.KnifeView extends Psg.WeaponView

  constructor: (model) ->
    @barrel = new Shape.Rectangle
      size:
        x: 0.6 * @scale
        y: 0.2 * @scale
    @barrel.fillColor = 'black'
    @line1 = new Path.Line(
      [@barrel.bounds.left, @barrel.bounds.top],
      [@barrel.bounds.right + 0.2 * @scale, @barrel.bounds.top])
    @line1.strokeColor = '#89e'

    @line2 = new Path.Line(
      [@barrel.bounds.left, @barrel.bounds.bottom],
      [@barrel.bounds.right + 0.2 * @scale, @barrel.bounds.bottom])
    @line2.strokeColor = '#89e'

    @shape = new Group @barrel, @line1, @line2
    if model.onBody
      @shapeOffset =
        x: 0.5 * @scale
        y: 0.05 * @scale
      @moveTo model.position

class Psg.PistolView extends Psg.WeaponView

  constructor: (model) ->
    @barrel = new Shape.Rectangle
      size:
        x: 0.6 * @scale
        y: 0.16 * @scale
    @barrel.fillColor = 'black'

    @n = new Shape.Rectangle
      size:
        x: 0.5 * @barrel.size.width
        y: 1.5 * @barrel.size.height
    @n.strokeColor = 'black'
    @n.fillColor = 'grey'
    @n.position =
      x: @barrel.position.x + 0.2 * @barrel.size.width
      y: @barrel.position.y - 0.1 * @barrel.size.height

    @grip = new Shape.Rectangle
      size:
        x: 0.36 * @scale
        y: 0.1 * @scale
    @grip.position =
      x: @barrel.position.x - 0.3 * @barrel.size.width
      y: @barrel.position.y + 0.6 * @barrel.size.height
    @grip.fillColor = 'black'
    @grip.rotate(100)

    @shape = new Group @barrel, @grip, @n
    if model.onBody
      @shapeOffset =
        x: 0.55 * @scale
        y: 0.15 * @scale
    else
      @shape.onFrame = =>
        @shape.visible = @respawn <= 0
    if model.position
      @moveTo model.position


class Psg.MachineGunView extends Psg.WeaponView

  constructor: (model) ->
    @barrel = new Shape.Rectangle(
      size: new Size(@scale, 0.16 * @scale)
    )
    @barrel.strokeColor = 'black'
    @barrel.fillColor = 'black'
    @grip = new Shape.Rectangle size: new Size(0.3 * @scale, 0.1 * @scale)
    @grip.position =
      x: @barrel.position.x - 0.3 * @barrel.size.width
      y: @barrel.position.y + @barrel.size.height
    @grip.strokeColor = 'black'
    @grip.fillColor = 'black'
    @grip.rotate(100)

    @grip2 = new Shape.Rectangle size: new Size(0.3 * @scale, 0.1 * @scale)
    @grip2.position =
      x: @barrel.position.x + 0.1 * @barrel.size.width
      y: @barrel.position.y + 0.8 * @barrel.size.height
    @grip2.strokeColor = 'black'
    @grip2.fillColor = 'black'
    @grip2.rotate(45)

    @shape = new Group @barrel, @grip, @grip2
    if model.onBody
      @shapeOffset =
        x: 0.55 * @scale
        y: 0.15 * @scale
    else
      @shape.onFrame = =>
        @shape.visible = @respawn <= 0
    if model.position
      @moveTo model.position


class Psg.RocketLauncherView extends Psg.WeaponView

  constructor: (model) ->
    @barrel = new Shape.Rectangle(
      size: new Size(1.4 * @scale, 0.24 * @scale)
    )
    @barrel.strokeColor = 'black'
    @barrel.fillColor = 'black'
    @grip = new Shape.Rectangle size: new Size(0.36 * @scale, 0.1 * @scale)
    @grip.position =
      x: @barrel.position.x - 0.4 * @scale
      y: @barrel.position.y + 0.08 * @scale
    @grip.strokeColor = 'black'
    @grip.fillColor = 'black'
    @grip.rotate(100)

    LINE_MARGIN = 0.04 * @scale
    @line = new Path.Line(
      [@barrel.bounds.left + LINE_MARGIN, @barrel.bounds.top + LINE_MARGIN],
      [@barrel.bounds.right - LINE_MARGIN, @barrel.bounds.top + LINE_MARGIN])
    @line.strokeColor = 'red'

    @shape = new Group @barrel, @grip, @line
    if model.onBody
      @shapeOffset =
        x: 0.5 * @scale
        y: 0.12 * @scale
    else
      @shape.onFrame = =>
        @shape.visible = @respawn <= 0
    if model.position
      @moveTo model.position


class Psg.RailGunView extends Psg.WeaponView

  constructor: (model) ->
    @barrel = new Shape.Rectangle(
      size: new Size(1.2 * @scale, 0.16 * @scale)
    )
    @barrel.strokeColor = 'black'
    @barrel.fillColor = 'black'
    @grip = new Shape.Rectangle(
      [@barrel.bounds.left, @barrel.bounds.top + 0.14 * @scale],
      [0.36 * @scale, 0.1 * @scale])
    @grip.strokeColor = 'black'
    @grip.fillColor = 'black'
    @grip.rotate(100)

    @s = new Path.RegularPolygon([@barrel.bounds.left, @barrel.bounds.top + 0.14 * @scale], 3, 0.3 * @scale)
    @s.fillColor = 'black'
    @s.scale(0.5, 1)
    @s.rotate(80)

    @n = new Shape.Rectangle(
      [@barrel.bounds.left + 0.3 * @scale, @barrel.bounds.top - 0.02 * @scale],
      [0.8 * @scale, 0.2 * @scale])
    @n.style =
      strokeColor: 'black'
      fillColor: '#57b'

    @shape = new Group @barrel, @grip, @s, @n
    if model.onBody
      @shapeOffset =
        x: 0.55 * @scale
        y: 0.15 * @scale
    else
      @shape.onFrame = =>
        @shape.visible = @respawn <= 0
    if model.position
      @moveTo model.position


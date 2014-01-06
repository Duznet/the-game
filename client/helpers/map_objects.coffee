class Psg.ObjectView

  scale: config.game.scale
  sign: 1
  shapeOffset: x: 0, y: 0

  moveTo: (newPosition) ->
    @shape.position = new Point
      x: newPosition.x + @sign * @shapeOffset.x
      y: newPosition.y + @sign * @shapeOffset.y

  getPosition: ->
    new Point
      x: @shape.position.x - @sign * @shapeOffset.x
      y: @shape.position.y - @sign * @shapeOffset.y

  flip: ->
    @sign *= -1
    @shape.scale(-1, 1)

  importPosition: (model) ->
    @moveTo x: model.position.x * @scale, y: model.position.y * @scale


class Psg.CrosshairView extends Psg.ObjectView

  saveOffset: (point) ->
    @offset =
      x: @shape.position.x - point.x
      y: @shape.position.y - point.y

  constructor: ->
    @offset = x: 0, y: 0
    @circle = new Shape.Circle new Point(0, 0), 0.3 * @scale
    @shape = new Group @circle
    @shape.style = 
      strokeColor: 'black'
      strokeWidth: 3


class Psg.PlayerView extends Psg.ObjectView

  moveTo: (newPosition) ->
    super newPosition
    @label.position = x: @body.position.x, y: @body.position.y - @scale

  flip: ->
    @sign *= -1
    @shape.scale(-1, 1, @body.position)

  constructor: (model) ->
    @body = new Shape.Rectangle size: new Size(@scale, @scale)
    @body.strokeColor = 'black'
    @body.fillColor = 'red'

    @ribbon = new Shape.Rectangle(
      new Point(-0.1 * @body.size.width, 0.1 * @body.size.height),
      new Size(1.2 * @body.size.width, 0.2 * @body.size.height)
    )
    @ribbon.strokeColor = 'black'
    @ribbon.fillColor = 'black'

    @eye = new Path.RegularPolygon(
      new Point(0, 0),
      3,
      0.8 * @ribbon.size.height
    )
    @eye.scale(0.5, 1)
    @eye.rotate(90)
    @eye.position = new Point @ribbon.position.x + 0.35 * @ribbon.size.width, @ribbon.position.y
    @eye.strokeColor = 'black'
    @eye.fillColor = 'yellow'

    @head = new Group @ribbon, @eye
    @head.rotate(5)

    @label = new PointText
    @label.fillColor = 'black'
    @label.justification = 'center'
    @label.content = model.login

    @gun = new Psg.PistolView
      position: @body.position
      onBody: true

    @shape = new Group(@body, @head, @gun.shape)
    @shapeOffset = new Point
      x: @shape.position.x - @body.position.x
      y: @shape.position.y - @body.position.y
    if model then @importPosition model


class Psg.ProjectileView extends Psg.ObjectView

  SIZES:
    K: 0.1
    P: 0.1
    M: 0.1
    R: 0.2
    A: 0.2

  COLORS:
    K: 'grey'
    P: 'black'
    M: 'black'
    R: 'red'
    A: 'blue'

  constructor: (model) ->
    if model.weapon is 'A'
      @shape = new Path.Line(
        new Point(
          x: model.position.x * @scale
          y: model.position.y * @scale
        ),
        new Point(
          x: (model.position.x + model.velocity.x) * @scale
          y: (model.position.y + model.velocity.y) * @scale
        )
      )
      @shape.strokeColor = 'blue'
      @shape.strokeWidth = 0.1 * @scale
    else
      @shape = new Path.Circle new Point(0, 0), @SIZES[model.weapon] * @scale
      @shape.strokeColor = 'black'
      @shape.fillColor = @COLORS[model.weapon]
      if model then @importPosition model


class Psg.WeaponOnMapView extends Psg.ObjectView

  moveTo: (newPosition) ->
    super newPosition
    @text.position = @rect.position

  constructor: (model) ->
    @type = model.type
    @respawn = model.respawn
    @rect = new Shape.Rectangle size: new Size(@scale * 0.6, @scale * 0.6)
    @rect.fillColor = 'yellow'
    @rect.strokeColor = 'black'

    @text = new PointText
    @text.fillColor = 'black'
    @text.justification = 'center'
    @text.content = @type
    @text.fontSize = @scale / 2

    @shape = @rect
    @importPosition model
    @shape.onFrame = =>
      @shape.visible = @respawn <= 0


class Psg.WeaponView extends Psg.ObjectView

  constructor: (model) ->


class Psg.KnifeView extends Psg.WeaponView

  constructor: (model) ->


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
    if not model.onBody
      @scale *= 0.8
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


class Psg.RailGunView extends Psg.WeaponView

  constructor: (model) ->

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

    @gun = new Psg.MachineGunView
      position: @body.position

    @shape = new Group(@body, @head, @gun.shape)
    @shapeOffset = new Point
      x: @shape.position.x - @body.position.x
      y: @shape.position.y - @body.position.y
    if model then @importPosition model


class Psg.ProjectileView extends Psg.ObjectView

  constructor: (model) ->
    @shape = new Path.Circle new Point(0, 0), 0.1 * @scale
    @shape.strokeColor = 'black'
    @shape.fillColor = 'black'
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

    @shape = new Group @barrel, @grip
    @shapeOffset =
      x: 0.55 * @scale
      y: 0.15 * @scale
    if model.position
      @moveTo model.position


class Psg.RocketLauncherView extends Psg.WeaponView

  constructor: (model) ->


class Psg.RailGunView extends Psg.WeaponView

  constructor: (model) ->

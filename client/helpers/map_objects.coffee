class Psg.ObjectView

  scale: config.game.scale
  sign: 1
  shapeOffset: x: 0, y: 0

  moveTo: (newPosition) ->
    @shape.position = new Point
      x: newPosition.x - @shapeOffset.x
      y: newPosition.y - @shapeOffset.y

  getPosition: ->
    new Point
      x: @shape.position.x + @shapeOffset.x
      y: @shape.position.y + @shapeOffset.y

  flip: ->
    @sign *= -1
    @shape.scale(-1, 1)

  importPosition: (model) ->
    @moveTo x: model.position.x * @scale, y: model.position.y * @scale


class Psg.PlayerView extends Psg.ObjectView

  moveTo: (newPosition) ->
    super newPosition
    @label.position = x: @body.position.x, y: @body.position.y - @scale

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
    @eye.scale(0.6, 1)
    @eye.rotate(90)
    @eye.position = new Point @ribbon.position.x + 0.4 * @ribbon.size.width, @ribbon.position.y
    @eye.strokeColor = 'black'
    @eye.fillColor = 'yellow'

    @head = new Group @ribbon, @eye
    @head.rotate(5)

    @label = new PointText new Point(0, 0)
    @label.fillColor = 'black'
    @label.justification = 'center'
    @label.content = model.login

    @barrel = new Shape.Rectangle(
      new Point(@body.position.x + 0.1 * @body.size.width, @body.position.y - 0.05 * @body.size.height),
      new Size(@body.size.width, 0.1 * @body.size.height)
    )
    @barrel.strokeColor = 'black'
    @barrel.fillColor = 'black'
    @handle = new Shape.Rectangle size: new Size(0.3 * @body.size.width, 0.05 * @body.size.height)
    @handle.position =
      x: @barrel.position.x - 0.3 * @barrel.size.width
      y: @barrel.position.y + @barrel.size.height
    @handle.strokeColor = 'black'
    @handle.fillColor = 'black'
    @handle.rotate(100)

    @shape = new Group(@body, @head, @barrel, @handle)
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

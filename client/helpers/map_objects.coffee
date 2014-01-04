class Psg.ObjectView

  scale: config.game.scale
  sign: 1
  shapeOffset: x: 0, y: 0

  moveTo: (newPosition) ->
    @shape.position = new Point
      x: newPosition.x - @shapeOffset.x
      y: newPosition.y - @shapeOffset.y

  onFrame: ->
    @visible = true

  getPosition: ->
    new Point
      x: @shape.position.x + @shapeOffset.x
      y: @shape.position.y + @shapeOffset.y

  flip: ->
    @sign *= -1
    @shape.scale(-1, 1)

class Psg.PlayerView extends Psg.ObjectView

  constructor: (attrs) ->
    attrs = attrs || {}
    @body = new Shape.Rectangle new Point(0, 0), new Size(@scale, @scale)
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

    @shape = new Group(@body, @head)
    @shape.visible = false
    @shapeOffset = new Point
      x: @shape.position.x - @body.position.x
      y: @shape.position.y - @body.position.y

    @shape.onFrame = @onFrame


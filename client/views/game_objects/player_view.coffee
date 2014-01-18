class Psg.PlayerView extends Psg.ObjectView

  moveTo: (newPosition) ->
    super newPosition
    @label.position = x: @body.position.x, y: @body.position.y - @scale

  flip: ->
    @sign *= -1
    @shape.scale(-1, 1, @body.position)

  hide: ->
    @shape.visible = false
    @label.visible = false

  show: ->
    @shape.visible = true
    @label.visible = true

  remove: ->
    super()
    @label.remove()

  constructor: (model) ->
    @body = new Shape.Rectangle size: new Size(@scale, @scale)
    @body.strokeColor = 'black'
    @body.fillColor = model.color

    @ribbon = new Shape.Rectangle(
      new Point(-0.1 * @body.size.width, 0.1 * @body.size.height),
      new Size(1.2 * @body.size.width, 0.2 * @body.size.height)
    )
    @ribbon.strokeColor = 'black'
    @ribbon.fillColor = 'black'

    @eye = new Path.RegularPolygon(
      new Point(0, 0),
      3,
      0.14 * @scale
    )
    @eye.scale(0.5, 1)
    @eye.rotate(90)
    @eye.position = new Point @ribbon.position.x + 0.35 * @ribbon.size.width, @ribbon.position.y
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

    @wound = new Shape.Circle(@body.position, 0.8 * @scale)
    @wound.style =
      strokeColor: 'red'
      strokeWidth: 2
    @wound.visible = false

    @shape = new Group(@body, @head, @gun.shape, @wound)
    @shapeOffset = new Point
      x: @shape.position.x - @body.position.x
      y: @shape.position.y - @body.position.y
    @importPosition model

class Psg.CrosshairView extends Psg.ObjectView

  saveOffset: (point) ->
    @offset =
      x: @shape.position.x - point.x
      y: @shape.position.y - point.y

  constructor: ->
    @offset = x: 0, y: 0
    @circle = new Shape.Circle new Point(0, 0), 0.3 * @scale
    @point = new Shape.Circle new Point(0, 0), 0.01 * @scale
    @shape = new Group @circle, @point
    @shape.style =
      strokeColor: 'slategrey'
      strokeWidth: 3

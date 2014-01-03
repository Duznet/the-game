class Psg.ObjectView

  scale: config.game.scale

  shapeOffset: x: 0, y: 0

  moveTo: (newPosition) ->
    @shape.position = new Point
      x: @scale * (newPosition.x - @shapeOffset.x)
      y: @scale * (newPosition.y - @shapeOffset.y)
    @position = @shape.position

  onFrame: ->
    @visible = true


class Psg.PlayerView extends Psg.ObjectView

  constructor: (attrs) ->
    attrs = attrs || {}
    @shape = new Shape.Rectangle new Point(0, 0), new Size(@scale, @scale)
    @shape.visible = false
    @shape.strokeColor = 'black'
    @shape.fillColor = 'red'
    @position = @shape.position
    @shape.onFrame = @onFrame

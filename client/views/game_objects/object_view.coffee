class Psg.ObjectView

  scale: config.game.scale
  sign: 1
  shapeOffset: x: 0, y: 0

  moveTo: (newPosition) ->
    @shape.position = new Point
      x: newPosition.x + @sign * @shapeOffset.x
      y: newPosition.y + @shapeOffset.y


  getPosition: ->
    new Point
      x: @shape.position.x - @sign * @shapeOffset.x
      y: @shape.position.y - @shapeOffset.y

  flip: ->
    @sign *= -1
    @shape.scale(-1, 1)

  importPosition: (model) ->
    @moveTo x: model.position.x * @scale, y: model.position.y * @scale

  remove: ->
    if @shape?
      @shape.onFrame = null
      @shape.remove()

class Psg.MapItemView extends Psg.ObjectView

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

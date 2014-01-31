class Psg.MapItemView extends Psg.ObjectView

  isWeapon: ->
    'A' <= @type <= 'Z'

  onFrame: (event) =>
    @shape.visible = @respawn <= 0
    @shape.rotate 0.1 * Math.sin event.time
    @moveTo
      x: @shape.position.x
      y: @shape.position.y + 0.05 * Math.cos event.time

  constructor: (model) ->
    @type = model.type
    @respawn = model.respawn
    if @isWeapon()
      @gun = new Psg.WEAPONS[model.type] model
      @shape = @gun.shape
    else
      @rect = new Shape.Rectangle size: new Size(@scale * 0.6, @scale * 0.6)
      @rect.fillColor = 'yellow'
      @rect.strokeColor = 'black'

      @text = new PointText
        fillColor: 'black'
        justification: 'center'
        content: @type
        fontSize: @scale / 2
      @text.position = @rect.position

      @shape = new Group @rect, @text
      @importPosition model
    @shape.rotate -7
    @shape.onFrame = @onFrame


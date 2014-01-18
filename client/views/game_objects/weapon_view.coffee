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

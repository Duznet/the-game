class Psg.ProjectileView extends Psg.ObjectView

  finished: true

  SIZES:
    K: 0.1
    P: 0.1
    M: 0.1
    R: 0.2
    A: 0.2

  COLORS:
    K: 'grey'
    P: 'black'
    M: 'black'
    R: 'red'
    A: 'blue'

  constructor: (model) ->
    if model.velocity.x is 0 and model.velocity.y is 0 and model.weapon isnt 'R'
      @shape = null
      return
    if model.weapon is 'K'
      @shape = new Path.Star
        center: [0, 0]
        points: 8
        radius1: 0.1 * @scale
        radius2: 0.25 * @scale
      @shape.fillColor = 'black'
      @shape.strokeColor = '#89e'
      @shape.rotate(Math.round(360 * Math.random()))
      if model then @importPosition model

    if model.weapon is 'A'
      @finished = false
      @shape = new Path.Line(
        new Point(
          x: model.position.x * @scale
          y: model.position.y * @scale
        ),
        new Point(
          x: (model.position.x + model.velocity.x) * @scale
          y: (model.position.y + model.velocity.y) * @scale
        )
      )
      @shape.strokeColor = 'blue'
      @shape.strokeWidth = 0.1 * @scale
      @shape.strokeCap = 'round'
      @shape.onFrame = =>
        if @shape.strokeWidth < 0.3 * @scale
          @shape.strokeWidth *= 1.15
        if @shape.strokeColor.alpha > 0.2
          @shape.strokeColor.alpha -= 0.15
        else
          @finished = true
    else if model.weapon is 'R' and model.velocity.x is 0 and model.velocity.y is 0
      @finished = false
      @back = new Path.Star
        center: [model.position.x * @scale, model.position.y * @scale]
        points: 8 + Math.floor(Math.random() * 8)
        radius1: 0.4 * @scale
        radius2: 0.8 * @scale
        fillColor: 'red'
      @front = new Path.Star
        center: [model.position.x * @scale, model.position.y * @scale]
        points: 6 + Math.floor(Math.random() * 6)
        radius1: 0.13 * @scale
        radius2: 0.26 * @scale
        fillColor: 'yellow'
      @front.rotate(15)
      @back.smooth()
      @front.smooth()
      @shape = new Group(@back, @front)
      @count = 0
      @shape.onFrame = =>
        if @count < 5
          @back.scale(1.4)
          @front.scale(1.3)
          @back.fillColor.alpha /= 1.2
          @front.fillColor.alpha /= 1.1
          @front.rotate(5)
          @back.rotate(-1)
          @count++
        else
          @finished = true
    else if model.weapon isnt 'K'
      @shape = new Path.Circle new Point(0, 0), @SIZES[model.weapon] * @scale
      @shape.strokeColor = 'black'
      @shape.fillColor = @COLORS[model.weapon]
      if model then @importPosition model

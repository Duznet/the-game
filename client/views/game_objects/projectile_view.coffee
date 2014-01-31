class Psg.ProjectileView extends Psg.ObjectView

  finished: true

  minLifeTime: 1

  needsImportPosition: true

  rotate: (velocity) ->
    @shape.rotate Math.atan2(velocity.y, velocity.x) / Math.PI * 180

  initFly: (model) ->
    @shape = null

  initExplosion: (model) ->
    @shape = null

  constructor: (model) ->
    if model.velocity.x is 0 and model.velocity.y is 0
      @initExplosion model
      if @explosionFrame?
        console.log 'explosionFrame'
        @shape.onFrame = @explosionFrame
    else
      if model.lifeTime < @minLifeTime
        @shape = null
        return
      @initFly model
      if @flyFrame?
        console.log 'flyFrame'
        @shape.onFrame = @flyFrame
    if @shape? and @needsImportPosition
      @importPosition model


class Psg.KnifeProjectileView extends Psg.ProjectileView

  initFly: (movel) ->
    @shape = new Path.Star
      center: [0, 0]
      points: 8
      radius1: 0.1 * @scale
      radius2: 0.25 * @scale
      strokeColor: '#89e'
      fillColor: 'black'
    @shape.rotate(Math.round(360 * Math.random()))


class Psg.BulletView extends Psg.ProjectileView

  initFly: (model) ->
    @back = new Path.Star
      center: [-0.2 * @scale, 0]
      radius1: 0.3 * @scale
      radius2: 0.2 * @scale
      points: 3 + Math.round 3 * Math.random()
      fillColor: 'grey'
    @back.fillColor.alpha = 0.3
    @back.scale(1, 0.6)
    @back.smooth()
    @front = new Path.Circle
      center: [0, 0]
      radius: 0.2 * @scale
      strokeColor: 'black'
      fillColor: 'black'
    @front.removeSegments 0, 1
    @front.scale 1, 0.4
    @front.flatten(0.1 * @scale)
    @shape = new Group(@back, @front)
    @rotate model.velocity


class Psg.PistolProjectileView extends Psg.BulletView


class Psg.MachineGunProjectileView extends Psg.BulletView

  minLifeTime: 2


class Psg.RocketLauncherProjectileView extends Psg.ProjectileView

  initFly: (model) ->
    @shape = new Path.Circle
      center: [0, 0]
      radius: 0.2 * @scale
      strokeColor: 'black'
      fillColor: 'red'
    @rotate model.velocity

  explosionFrame: =>
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

  initExplosion: (model) ->
    @finished = false
    @back = new Path.Star
      center: [0, 0]
      points: 8 + Math.floor(Math.random() * 8)
      radius1: 0.4 * @scale
      radius2: 0.8 * @scale
      fillColor: 'red'
    @front = new Path.Star
      center: [0, 0]
      points: 6 + Math.floor(Math.random() * 6)
      radius1: 0.13 * @scale
      radius2: 0.26 * @scale
      fillColor: 'yellow'
    @front.rotate(15)
    @back.smooth()
    @front.smooth()
    @shape = new Group(@back, @front)
    @count = 0


class Psg.RailGunProjectileView extends Psg.ProjectileView

  needsImportPosition: false

  flyFrame: =>
    if @shape.strokeWidth < 0.3 * @scale
      @shape.strokeWidth *= 1.15
    if @shape.strokeColor.alpha > 0.2
      @shape.strokeColor.alpha -= 0.15
    else
      @finished = true

  initFly: (model) ->
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


Psg.PROJECTILES =
  K: Psg.KnifeProjectileView
  P: Psg.PistolProjectileView
  M: Psg.MachineGunProjectileView
  R: Psg.RocketLauncherProjectileView
  A: Psg.RailGunProjectileView

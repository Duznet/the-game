class Psg.Game extends Backbone.Model

  initialize: ->
    console.log 'Game initialize'
    @game = @get('user').game

  startGame: (attrs) ->
    @player = {}
    @player.movement = dx: 0, dy: 0
    @gc = new Psg.GameplayConnection sid: @get('user').get('sid')

    @gc.onopen = =>
      @gc.move @player.movement

    @gc.onmessage = attrs.onmessage || @gc.onmessage

    @sendActionInterval = setInterval =>
      if @player.movement.dx isnt 0 or @player.movement.dy isnt 0
        @gc.move @player.movement
    , config.defaultGameConsts.tickSize / 2

    @gc.onclose = =>
      clearInterval @sendActionInterval

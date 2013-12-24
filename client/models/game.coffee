class Psg.Game extends Backbone.Model

  initialize: ->
    console.log 'Game initialize'
    @game = @get('user').game


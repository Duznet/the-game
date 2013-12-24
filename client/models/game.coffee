class Psg.Game extends Backbone.Model

  initialize: ->
    console.log 'Game initialize'
    console.log 'user games: ', @get('user').games
    @game = _.find @get('user').games, (g) => parseInt(g.id) is parseInt(@get 'id')
    console.log 'game: ', @game
    @map = _.find @get('user').maps, (m) => parseInt(m.id) is parseInt(@game.id)
    console.log 'map: ', @map


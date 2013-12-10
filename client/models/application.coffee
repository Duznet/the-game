class Psg.Application extends Backbone.Model

  initialize: ->
    @conn = new Psg.GameConnection config.gameUrl
    @user = @get 'user'

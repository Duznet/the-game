class Psg.Application extends Backbone.Model

  initialize: ->
    @user = @get 'user'
    @conn = @user.conn

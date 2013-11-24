class Psg.Application extends Backbone.Model

  initialize: ->
    @conn = new Psg.GameConnection config.gameUrl
    @user = null

  signup: (login, password) ->
    @conn.signup(login, password).then (data) ->
      if data.result isnt 'ok'
        throw new Psg.GameError data.result
        @signin(login, password)

  signin: (login, password) ->
    @conn.signin(login, password).then (data) ->
      if data.result isnt 'ok'
        throw new Psg.GameError data.result
        @user = new Psg.User login: login, sid: data.sid

  signout: ->
    @conn.signout(@user.getSid()).then (data) ->
      if data.result isnt 'ok'
        throw new Psg.GameError data.result
        @user = null





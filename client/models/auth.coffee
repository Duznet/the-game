class Psg.Auth extends Backbone.Model

  initialize: ->
    @conn = new Psg.GameConnection config.gameUrl

  signup: (login, password) ->
    @conn.signup(login, password).then (data) ->
      if data.result is 'ok'
        @signin(login, password)
      else
        @trigger 'error', result: data.result

  signin: (login, password) ->
    @conn.signin(login, password).then (data) ->
      if data.result is 'ok'
        sessionStorage.setItem 'login', login
        sessionStorage.setItem 'sid', data.sid
        @trigger 'authenticated'
      else
        @trigger 'error', result: data.result

  signout: (sid) ->
    @conn.signout(sid).then (data) ->
      if data.result is 'ok'
        sessionStorage.clear()
      else
        @trigger 'error', result: data.result

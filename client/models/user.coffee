class Psg.User extends Backbone.Model

  initialize: ->
    @conn = new Psg.GameConnection config.gameUrl

  save: ->
    sessionStorage.setItem 'login', @get 'login'
    sessionStorage.setItem 'sid', @get 'sid'

  fetch: ->
    @set 'login', sessionStorage.getItem 'login'
    @set 'sid', sessionStorage.getItem 'sid'

  isAuthenticated: ->
    @fetch()
    @get('login') and @get('sid')

  signup: (login, password) ->
    @conn.signup(login, password).then (data) =>
      if data.result is 'ok'
        @signin(login, password)
      else
        @trigger 'submitFailed', data.result

  signin: (login, password) ->
    @conn.signin(login, password).then (data) =>
      if data.result is 'ok'
        @set 'login', login
        @set 'sid', data.sid
        @save()
        @trigger 'authenticated'
      else
        @trigger 'submitFailed', data.result

  signout: (sid) ->
    @conn.signout(sid).then (data) =>
      if data.result is 'ok'
        @set 'login', null
        @set 'sid', null
        sessionStorage.clear()
        @trigger 'signedOut'
      else
        @trigger 'submitFailed', data.result

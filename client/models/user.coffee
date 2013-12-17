class Psg.User extends Backbone.Model

  initialize: ->
    @conn = @get 'conn'
    @storage = config.storage
    @fetch()
    @listenTo @conn, 'sessionLost', @onSessionLost

  onSessionLost: ->
    @trigger 'signedOut'

  save: ->
    @storage.setItem 'login', @get 'login'
    @storage.setItem 'sid', @get 'sid'
    @conn.sid = @get 'sid'

  fetch: ->
    @set 'login', @storage.getItem 'login'
    @set 'sid', @storage.getItem 'sid'
    @conn.sid = @get 'sid'

  isAuthenticated: ->
    @fetch()
    @get('login') and @get('sid')

  signup: (login, password) ->
    @conn.signup(login: login, password: password).then (data) =>
      if data.result is 'ok'
        @signin(login, password)
      else
        @trigger 'submitFailed', data.result

  signin: (login, password) ->
    @conn.signin(login: login, password: password).then (data) =>
      if data.result is 'ok'
        @set 'login', login
        @set 'sid', data.sid
        @save()
        @trigger 'authenticated'
      else
        @trigger 'submitFailed', data.result

  signout: ->
    @conn.signout().then (data) =>
      if data.result is 'ok'
        @set 'login', null
        @set 'sid', null
        @trigger 'signedOut'
      else
        @trigger 'submitFailed', data.result

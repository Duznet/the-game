class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'

  initialize: ->

  checkAuth: ->
    @user =
      sid: sessionStorage.getItem 'sid'
      login: sessionStorage.getItem 'login'

    @user.sid and @user.login

  auth: ->
    console.log 'auth'
    wv = new Psg.AuthView model: new Psg.Auth
    $('#nav-signin').click()

  dashboard: ->
    if not @checkAuth()
      @navigate 'auth', trigger: true
    console.log 'dashboard'








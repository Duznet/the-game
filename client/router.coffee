class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'

  initialize: ->
    @user = new Psg.User

  auth: ->
    console.log 'auth'
    wv = new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  dashboard: ->
    if not @user.isAuthenticated()
      @navigate 'auth', trigger: true
      return
    console.log 'dashboard'

class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'

  initialize: ->
    @user = new Psg.User
    @user.on 'authenticated', @onAuthenticated
    @user.on 'signedOut', @onSignedOut

  onAuthenticated: =>
    @navigate 'dashboard', trigger: true

  onSignedOut: =>
    @navigate 'auth', trigger: true

  auth: ->
    console.log 'auth'
    wv = new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  dashboard: ->
    if not @user.isAuthenticated()
      @navigate 'auth', trigger: true
      return
    new Psg.ApplicationView
      model: new Psg.Application
        user: @user
    new Psg.ChatView
      model: new Psg.Chat
        sid: @user.get 'sid'
        game: ""
    console.log 'dashboard'

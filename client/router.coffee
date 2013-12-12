class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'
    'signout': 'signout'

  initialize: ->
    @conn = new Psg.GameConnection
      url: config.gameUrl
      sid: ''
    @user = new Psg.User
      conn: @conn

    @globalChat = new Psg.Chat
      game: ''
      user: @user

    @user.on 'authenticated', @onAuthenticated
    @user.on 'signedOut', @onSignedOut

  onAuthenticated: =>
    @navigate 'dashboard', trigger: true

  onSignedOut: =>
    sessionStorage.clear()
    @navigate 'auth', trigger: true

  auth: ->
    console.log 'auth'
    @globalChat.stopRefreshing()
    wv = new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  signout: ->
    @user.signout()

  dashboard: ->
    if not @user.isAuthenticated()
      @navigate 'auth', trigger: true
      return

    @globalChat.startRefreshing()
    new Psg.ApplicationView
      model: new Psg.Application
        user: @user

    new Psg.ChatView
      model: @globalChat

    console.log 'dashboard'

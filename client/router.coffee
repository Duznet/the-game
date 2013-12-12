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
    console.log 'conn: ', @conn
    @user = new Psg.User
      conn: @conn

    @globalChat = new Psg.Chat
      game: ''
      user: @user

    @user.on 'authenticated', @onAuthenticated
    @user.on 'signedOut', @onSignedOut

  onAuthenticated: =>
    @globalChat.startRefreshing()
    @navigate 'dashboard', trigger: true

  onSignedOut: =>
    sessionStorage.clear()
    @globalChat.stopRefreshing()
    @navigate 'auth', trigger: true

  auth: ->
    console.log 'auth'
    wv = new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  signout: ->
    @user.signout()

  dashboard: ->
    if not @user.isAuthenticated()
      @navigate 'auth', trigger: true
      return

    new Psg.ApplicationView
      model: new Psg.Application
        user: @user

    new Psg.ChatView
      model: @globalChat

    console.log 'dashboard'

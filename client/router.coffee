class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'
    'join': 'join'
    'signout': 'signout'

  initialize: ->

    @views = []

    @conn = new Psg.GameConnection
      url: config.gameUrl
      sid: ''
    @user = new Psg.User
      conn: @conn

    @globalChat = new Psg.Chat
      game: ''
      user: @user

    @gameList = new Psg.GameList
      user: @user

    @listenTo @user, 'authenticated', @onAuthenticated
    @listenTo @user, 'signedOut', @onSignedOut

  onAuthenticated: ->
    @navigate 'dashboard', trigger: true

  onSignedOut: ->
    sessionStorage.clear()
    @navigate 'auth', trigger: true

  addView: (view) ->
    @views.push view

  removeViews: ->
    for v in @views
      v.remove()
    @views = []

  auth: ->
    console.log 'auth'
    @removeViews()
    @globalChat.stopRefreshing()
    @gameList.stopRefreshing()
    @addView 'main', new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  signout: ->
    @user.signout()

  join: ->
    @removeViews 'main'
    if not @user.isAuthenticated()
      @navigate 'auth', trigger: true
      return

  dashboard: ->
    @removeViews 'all'
    if not @user.isAuthenticated()
      @navigate 'auth', trigger: true
      return

    @globalChat.startRefreshing()
    @gameList.startRefreshing()
    new Psg.ApplicationView
      model: new Psg.Application
        user: @user

    @addView 'sidebar', new Psg.ChatView
      model: @globalChat

    @addView 'main', new Psg.GameListView
      model: @gameList

    console.log 'dashboard'

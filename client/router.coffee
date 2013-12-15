class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'
    'signout': 'signout'

  initialize: ->

    @views =
      main: []
      sidebar: []

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

  addView: (group, view) ->
    @views[group].push view

  removeViews: (group) ->
    if group is 'all'
      for g of @views
        @removeViews g
    else
      for v in @views[group]
        v.remove()
      @views[group] = []

  auth: ->
    console.log 'auth'
    @removeViews 'all'
    @globalChat.stopRefreshing()
    @gameList.stopRefreshing()
    @wv = new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  signout: ->
    @user.signout()

  dashboard: ->
    @removeViews 'all'
    if @wv then @wv.remove()
    if not @user.isAuthenticated()
      @navigate 'auth', trigger: true
      return

    @globalChat.startRefreshing()
    @gameList.startRefreshing()
    new Psg.ApplicationView
      model: new Psg.Application
        user: @user

    new Psg.ChatView
      model: @globalChat

    new Psg.GameListView
      model: @gameList

    console.log 'dashboard'

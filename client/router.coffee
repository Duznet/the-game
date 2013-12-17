class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'
    'join': 'join'
    'signout': 'signout'

  initialize: ->

    @views = []
    @refreshingComponents = []

    @conn = new Psg.GameConnection
      url: config.gameUrl
      sid: ''
    @user = new Psg.User
      conn: @conn

    @app = new Psg.Application
      user: @user

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

  clearPage: ->
    @removeViews()
    @stopComponentRefreshings()

  refreshPage: ->
    @clearPage()

    if not @user.isAuthenticated()
      @onSignedOut()

    if not @appView
      @appView = new Psg.ApplicationView model: @app
    else
      @appView.render()
    @addView @appView

  addView: (view) ->
    @views.push view

  removeViews: ->
    for v in @views
      v.remove()
    @views = []

  addRefreshingComponent: (component) ->
    @refreshingComponents.push component
    component.startRefreshing()

  stopComponentRefreshings: ->
    for c in @refreshingComponents
      c.stopRefreshing()
    @refreshingComponents = []

  auth: ->
    console.log 'auth'
    @clearPage()
    @addView new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  signout: ->
    @user.signout()

  join: ->
    @refreshPage()
    @addRefreshingComponent @globalChat
    @addRefreshingComponent @gameList
    @addView new Psg.ChatView model: @globalChat
    @addView new Psg.GameListView model: @gameList

  dashboard: ->
    console.log 'dashboard'
    @join()

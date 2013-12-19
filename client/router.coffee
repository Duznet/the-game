class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'
    'join': 'join'
    'upload-map': 'uploadMap'
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
    @user.storage.clear()
    @navigate 'auth', trigger: true

  clearPage: ->
    @removeViews()

  refreshPage: ->
    @clearPage()

    if not @user.isAuthenticated()
      @onSignedOut()
      return

    if not @appView
      @appView = new Psg.ApplicationView model: @app
    else
      @appView.render()
    @addView @appView

  addView: (view) ->
    @views.push view
    console.log 'pushing v: ', view
    if view.model and typeof view.model.startRefreshing isnt 'undefined'
      console.log 'and start refreshing it'
      view.model.startRefreshing()

  removeViews: ->
    for v in @views
      console.log 'removing v: ', v
      v.remove()
      if v.model and typeof v.model.stopRefreshing isnt 'undefined'
        v.model.stopRefreshing()
    @views = []

  auth: ->
    console.log 'auth'
    @clearPage()
    @addView new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  signout: ->
    @user.signout()

  join: ->
    @refreshPage()
    @addView new Psg.ChatView model: @globalChat
    @addView new Psg.GameListView model: @gameList

  uploadMap: ->
    console.log 'uploadMap'
    @refreshPage()
    @addView new Psg.ChatView model: @globalChat
    @addView new Psg.MapUploaderView
      model: new Psg.MapUploader
        user: @user

  dashboard: ->
    console.log 'dashboard'
    @join()

class Psg.Router extends Backbone.Router

  routes:
    '': 'dashboard'
    'auth': 'auth'
    'dashboard': 'dashboard'
    'join': 'join'
    'create': 'create'
    'upload-map': 'uploadMap'
    'signout': 'signout'
    'game/:id': 'game'
    'leave': 'leave'

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

    @gameCreator = new Psg.GameCreator
      user: @user

    @listenTo @user, 'authenticated', @onAuthenticated
    @listenTo @user, 'signedOut', @onSignedOut
    @listenTo @user, 'enteredGame', @onEnteredGame
    @listenTo @user, 'leftGame', @onLeftGame

  onAuthenticated: ->
    @navigate 'dashboard', trigger: true

  onSignedOut: ->
    @user.storage.clear()
    @navigate 'auth', trigger: true

  onEnteredGame: (id) ->
    @navigate "game/#{id}"
    @refreshPage(pageTitle: "Playing '#{@user.game.name}'")
    @addView new Psg.ChatView
      model: new Psg.Chat
        user: @user
        game: id
    gameView = new Psg.GameView
      model: new Psg.Game
        user: @user
        id: id
    @addView gameView
    gameView.startGame()

  onLeftGame: ->
    @navigate 'dashboard', trigger: true

  clearPage: ->
    @removeViews()


  refreshPage: (attrs) ->
    @clearPage()

    if not @user.isAuthenticated()
      @onSignedOut()
      return false
    @app.set 'pageTitle', attrs.pageTitle
    if not @appView
      @appView = new Psg.ApplicationView model: @app
    else
      @appView.render()
    @addView @appView
    return true

  addView: (view) ->
    @views.push view
    if config.debug.pushingViewsInfo then console.log 'pushing v: ', view
    if view.model and typeof view.model.startRefreshing isnt 'undefined'
      if config.debug.pushingViewsInfo then console.log 'and start refreshing it'
      view.model.startRefreshing()

  removeViews: ->
    for v in @views
      if config.debug.pushingViewsInfo then console.log 'removing v: ', v
      v.remove()
      if v.model and typeof v.model.stopRefreshing isnt 'undefined'
        v.model.stopRefreshing()
      if v.model and typeof v.model.closeConnection isnt 'undefined'
        v.model.closeConnection()
    @views = []

  auth: ->
    console.log 'auth'
    @clearPage()
    @addView new Psg.WelcomeView model: @user
    $('#nav-signin').click()

  signout: ->
    @user.signout()

  join: ->
    if not @refreshPage(pageTitle: 'Join game') then return
    @addView new Psg.ChatView model: @globalChat
    @addView new Psg.GameListView model: @gameList

  create: ->
    if not @refreshPage(pageTitle: 'Create game') then return
    @addView new Psg.ChatView model: @globalChat
    @gameCreator = new Psg.GameCreator
      user: @user
    @addView new Psg.GameCreatorView
      model: @gameCreator

    @listenTo @gameCreator, 'created', @onGameCreated

  uploadMap: ->
    console.log 'uploadMap'
    if not @refreshPage(pageTitle: 'Upload map') then return
    @addView new Psg.ChatView model: @globalChat
    @addView new Psg.MapUploaderView
      model: new Psg.MapUploader
        user: @user

  dashboard: ->
    console.log 'dashboard'
    @join()

  game: (id) ->
    console.log "game #{id}"
    @user.joinGame parseInt id

  leave: ->
    console.log 'leaving game'
    @user.leaveGame()

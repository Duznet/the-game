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
    @listenTo @gameCreator, 'created', @onGameCreated

  onAuthenticated: ->
    @navigate 'dashboard', trigger: true

  onSignedOut: ->
    @user.storage.clear()
    @navigate 'auth', trigger: true

  onGameCreated: (id) ->
    console.log 'game created'
    @navigate "game/#{id}", trigger: true

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

  create: ->
    @refreshPage()
    @addView new Psg.ChatView model: @globalChat
    @gameCreator = new Psg.GameCreator
      user: @user
    @addView new Psg.GameCreatorView
      model: @gameCreator

    @listenTo @gameCreator, 'created', @onGameCreated

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

  game: (id) ->
    console.log "game #{id}"

    addGameView = =>
      console.log 'adding game view'
      @addView new Psg.ChatView
        model: new Psg.Chat
          user: @user
          game: id
      gameModel = new Psg.Game
          user: @user
          id: id
      @addView new Psg.GameView
        model: gameModel
      gameModel.ready()

    @refreshPage()
    @user.getGames().then =>
      console.log 'after getting games'
      isInGame = @user.isInGame(id)
      console.log 'user isInGame result: ', isInGame
      if isInGame
        console.log 'user is in the game'
        addGameView()
      else
        console.log 'user is not in that game'
        @user.leaveGame().then (data) =>
          console.log 'leave game response: ', data
          if data.result is 'ok' or data.result is 'notInGame'
            @user.joinGame(id).then (data) =>
              if data.result is 'ok' then addGameView()

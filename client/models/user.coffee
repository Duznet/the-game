class Psg.User extends Backbone.Model

  initialize: ->
    @conn = @get 'conn'
    @storage = config.storage
    @fetch()
    @listenTo @conn, 'sessionLost', @onSessionLost

  onSessionLost: ->
    @trigger 'signedOut'

  save: ->
    @storage.setItem 'login', @get 'login'
    @storage.setItem 'sid', @get 'sid'
    @conn.sid = @get 'sid'

  fetch: ->
    @set 'login', @storage.getItem 'login'
    @set 'sid', @storage.getItem 'sid'
    @conn.sid = @get 'sid'

  isAuthenticated: ->
    @fetch()
    @get('login') and @get('sid')

  findGame: ->
    games = []
    maps = []
    @conn.getGames()
    .then (data) =>
      if data.result is 'ok'
        games = data.games
        @conn.getMaps()
    .then (data) =>
      if data.result is 'ok'
        maps = data.maps
        game = _.find(games, (g) => _.find g.players, (p) => p is @get('login'))
        game.map = _.find(maps, (m) => parseInt(m.id) is parseInt(game.map))
        console.log 'game: ', game
        if game
          @game = game
          @trigger 'enteredToGame', @game.id
        else
          @game = null

  getGames: ->
    @conn.getGames().then (data) =>
      dfd = new $.Deferred
      if data.result is 'ok'
        @games = data.games
        @conn.getMaps().then (data) =>
          if data.result is 'ok'
            @maps = data.maps
            dfd.resolve()
      dfd

  isInGame: (id) ->
    @fetch()
    game = _.find(@games, (g) => _.find g.players, (p) => p is @get('login'))
    console.log game
    if game
      if id
        console.log 'game.id: ', game.id
        console.log 'id: ', id
        parseInt(game.id) is parseInt(id)
    else
      console.log 'user is not in any game'
      false


  leaveGame: ->
    @conn.leaveGame()

  joinGame: (gameId) ->
    @conn.joinGame
      game: gameId

  signup: (login, password) ->
    @conn.signup(login: login, password: password).then (data) =>
      if data.result is 'ok'
        @signin(login, password)
      else
        @trigger 'submitFailed', data.result

  signin: (login, password) ->
    @conn.signin(login: login, password: password).then (data) =>
      if data.result is 'ok'
        @set 'login', login
        @set 'sid', data.sid
        @save()
        @trigger 'authenticated'
      else
        @trigger 'submitFailed', data.result

  signout: ->
    @conn.signout().then (data) =>
      if data.result is 'ok'
        @set 'login', null
        @set 'sid', null
        @trigger 'signedOut'
      else
        @trigger 'submitFailed', data.result


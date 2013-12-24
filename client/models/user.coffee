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

  findCurGame: (games) ->
    _.find(games, (g) => _.find g.players, (p) => p is @get('login'))

  enterGame: ->
    console.log 'entering the game'
    @conn.getGames()
    .then (data) =>
      @game = @findCurGame(data.games)
      if not @game
        console.log 'user suddenly is not playing any game'
        return
      @conn.getMaps()
    .then (data) =>
      @game.map = _.find data.maps, (m) => parseInt(m.id) is @game.map
      console.log 'entered the game'
      @trigger 'enteredGame', @game.id

  joinGame: (gameId) ->
    @conn.getGames().then (data) =>
      console.log 'checking if user is playing this game'
      game = @findCurGame(data.games)
      if game and gameId is game.id
        console.log 'user is playing this game'
        @enterGame()
      else
        console.log 'user is not playing this game'
        @conn.leaveGame()
        .then =>
          @conn.joinGame(game: gameId)
        .then (data) =>
          console.log 'joining game'
          if data.result is 'ok' then @enterGame()

  leaveGame: ->
    @conn.leaveGame()

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


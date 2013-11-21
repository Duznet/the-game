class window.User
  constructor: (@login, @password) ->
    @conn = new Psg.GameConnection config.gameUrl
    # available values: "notSignedUp", "offline", "online", "playing"
    @status = "notSignedUp"

  signup: ->
    @conn.signup(@login, @password)

  signin: ->
    r = @conn.signin(@login, @password)
    r.then (data) =>
      @sid = data.sid
      r

  signout: ->
    r = @conn.signout(@sid)
    delete @sid
    r

  sendMessage: (gameId, text) ->
    @conn.sendMessage @sid, gameId, text

  getMessages: (gameId, since) ->
    @conn.getMessages @sid, gameId, since

  uploadMap: (name, maxPlayers, mapData) ->
    @conn.uploadMap @sid, name, maxPlayers, mapData

  getMaps: ->
    @conn.getMaps @sid

  createGame: (name, maxPlayers, mapId) ->
    @conn.createGame @sid, name, maxPlayers, mapId

  getGames: ->
    @conn.getGames @sid

  joinGame: (gameId) ->
    @conn.joinGame @sid, gameId

  leaveGame: ->
    @conn.leaveGame @sid

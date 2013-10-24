class window.User
  constructor: (@login, @password, @conn) ->

  signup: ->
    @conn.signup(@login, @password).result

  signin: ->
    r = @conn.signin(@login, @password)
    @sid = r.sid

  signout: ->
    r = @conn.signout(@sid)
    delete @sid

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

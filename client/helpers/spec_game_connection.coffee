class Psg.GameConnection extends Psg.Connection
  constructor: (@url) ->

  send: (requestData) ->
    $.ajax
      type: "POST"
      url: @url
      dataType: "json"
      contentType: "application/json"
      data: requestData

  startTesting: (websocketMode) ->
    @request "startTesting", websocketMode: websocketMode

  signup: (login, password) ->
    @request "signup",
      login: login
      password: password

  signin: (login, password) ->
    @request "signin",
      login: login
      password: password

  signout: (sid) ->
    @request "signout",
      sid: sid

  sendMessage: (sid, game, text) ->
    @request "sendMessage",
      sid: sid
      game: game
      text: text

  getMessages: (sid, game, since) ->
    @request "getMessages",
      sid: sid
      game: game
      since: since

  uploadMap: (sid, name, maxPlayers, mapData) ->
    @request "uploadMap",
      sid: sid
      name: name
      maxPlayers: maxPlayers
      map: mapData

  getMaps: (sid) ->
    @request "getMaps",
      sid: sid

  createGame: (sid, name, maxPlayers, mapId, consts) ->
    params =
      sid: sid
      name: name
      maxPlayers: maxPlayers
      map: mapId
    if consts?
      params.consts = consts
    @request "createGame", params


  getGames: (sid) ->
    @request "getGames",
      sid: sid

  joinGame: (sid, gameId) ->
    @request "joinGame",
      sid: sid
      game: gameId

  leaveGame: (sid) ->
    @request "leaveGame",
      sid: sid

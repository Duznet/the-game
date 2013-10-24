window.sendMessage = (websocket, action, params) ->
  websocket.send JSON.stringify
    action: action
    params: params


window.getResponse = (action, params) ->
  responseData = null
  $.ajax
    type: "POST"
    url: config.getDefaultUrl()
    dataType: "json"
    contentType: "application/json"
    async: false
    data: JSON.stringify(
      action: action
      params: params
    )
    success: (data) ->
      responseData = data

  responseData


window.startTesting = ->
  getResponse "startTesting"


window.signup = (login, password) ->
  getResponse "signup",
    login: login
    password: password


window.signin = (login, password) ->
  getResponse "signin",
    login: login
    password: password


window.signout = (sid) ->
  getResponse "signout",
    sid: sid


window.sendMessage = (sid, game, text) ->
  getResponse "sendMessage",
    sid: sid
    game: game
    text: text


window.getMessages = (sid, game, since) ->
  getResponse "getMessages",
    sid: sid
    game: game
    since: since


window.createGame = (sid, name, map, maxPlayers) ->
  getResponse "createGame",
    sid: sid
    name: name
    map: map
    maxPlayers: maxPlayers


window.getGames = (sid) ->
  getResponse "getGames",
    sid: sid


window.joinGame = (sid, game) ->
  getResponse "joinGame",
    sid: sid
    game: game


window.leaveGame = (sid) ->
  getResponse "leaveGame",
    sid: sid


window.uploadMap = (sid, name, maxPlayers, map) ->
  getResponse "uploadMap",
    sid: sid
    name: name
    maxPlayers: maxPlayers
    map: map


window.getMaps = (sid) ->
  getResponse "getMaps",
    sid: sid

window.move = (websocket, sid, tick, dx, dy) ->
  sendMessage websocket,
    "move",
    sid: sid
    tick: tick
    dx: dx
    dy: dy
class window.GameplayConnector extends Connector

  constructor: (@url) ->
    @ws = new WebSocket @url

  send: (requestData) ->
    @ws.send requestData

  move: (sid, tick, dx, dy) ->
    @request "move",
      sid: sid,
      tick: tick,
      dx: dx,
      dy: dy

class window.GameplayConnection extends Connection

  constructor: (@url) ->
    @ws = new WebSocket @url

    @ws.onopen = =>
      @onopen()

    @ws.onclose = (event) =>
      @onclose event

    @ws.onmessage = (event) =>
      data = JSON.parse event.data
      @onmessage data

    @ws.onerror = (error) =>
      @onerror error


  send: (requestData) ->
    @ws.send requestData

  close: ->
    @ws.close()

  move: (sid, tick, dx, dy) ->
    @request "move",
      sid: sid,
      tick: tick,
      dx: dx,
      dy: dy

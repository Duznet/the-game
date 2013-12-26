class Psg.GameplayConnection extends Psg.Connection

  constructor: (attrs) ->
    @url = attrs.url || config.gameplayUrl
    @sid = attrs.sid
    @tick = 0

    @ws = new WebSocket @url
    @ws.onopen = (event) =>
      @onopen event
    @ws.onmessage = (event) =>
      data = JSON.parse event.data
      if data.tick < @tick
        return
      @tick = data.tick
      @onmessage data
    @ws.onerror = (event) =>
      @onerror event
    @ws.onclose = (event) =>
      @onclose event

  send: (data) ->
    @ws.send data

  __request__: (action, params) ->
    params = params || {}
    params.tick = @tick
    params.sid = @sid
    @request action, params

  onopen: (data) ->
    #default placeholder

  onclose: (data) ->
    #default placeholder

  onmessage: (data) ->
    #default placeholder

  onerror: (data) ->
    #default placeholder


  move: (params) ->
    @__request__ 'move', params

  fire: (params) ->
    @__request__ 'fire', params

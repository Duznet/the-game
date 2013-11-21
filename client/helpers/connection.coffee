class Psg.Connection
  constructor: (@url) ->

  request: (action, params) ->
    response = @send JSON.stringify action: action, params: params
